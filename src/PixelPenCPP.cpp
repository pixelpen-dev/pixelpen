#include "PixelPenCPP.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <queue>

using namespace godot;


void PixelPenCPP::_bind_methods(){
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_image_flood", "started_point", "p_color_map", "mask_margin", "grow_only_along_axis"), &PixelPenCPP::get_image_flood);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_mask_used_rect", "p_mask"), &PixelPenCPP::get_mask_used_rect);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("coor_inside_canvas", "x", "y", "size", "p_mask"), &PixelPenCPP::coor_inside_canvas);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_color_map_with_mask", "p_mask", "p_color_map"), &PixelPenCPP::get_color_map_with_mask);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_mask_from_polygon", "polygon", "mask_size", "mask_margin"), &PixelPenCPP::get_mask_from_polygon);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("empty_index_on_color_map", "p_mask", "p_color_map"), &PixelPenCPP::empty_index_on_color_map);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("blit_color_map", "p_src_map", "p_mask", "offset", "p_color_map"), &PixelPenCPP::blit_color_map);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("swap_color", "palette_index_a", "palette_index_b", "p_color_map"), &PixelPenCPP::swap_color);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("replace_color", "palette_index_from", "palette_index_to", "p_color_map"), &PixelPenCPP::replace_color);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("swap_palette", "old_palette", "new_palette", "p_color_map"), &PixelPenCPP::swap_palette);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("move_shift", "direction", "p_image"), &PixelPenCPP::move_shift);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("blend", "p_target_image", "p_src_image", "offset"), &PixelPenCPP::blend);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("fill_color", "p_mask1_image", "p_target_image", "color", "p_mask2_image"), &PixelPenCPP::fill_color);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("fill_rect_outline", "rect", "color", "p_target", "p_mask"), &PixelPenCPP::fill_rect_outline);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("clean_invisible_color", "p_color_map", "palette"), &PixelPenCPP::clean_invisible_color);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("import_image", "p_layer_image", "p_imported_image", "palette"), &PixelPenCPP::import_image);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_image", "palette_color", "p_color_map", "mipmap"), &PixelPenCPP::get_image);
    ClassDB::bind_static_method("PixelPenCPP", D_METHOD("get_image_with_mask", "palette_color", "p_color_map" , "p_mask", "mipmap"), &PixelPenCPP::get_image_with_mask);
}


PixelPenCPP::PixelPenCPP(){
}

PixelPenCPP::~PixelPenCPP(){
}


Ref<Image> PixelPenCPP::get_image_flood(Vector2i started_point, const Ref<Image>  &p_color_map, Vector2i mask_margin = Vector2i(1, 1), const bool grow_only_along_axis = false){
    Vector2i canvas_size = p_color_map->get_size();
    Ref<Image> image = Image::create(canvas_size.x, canvas_size.y, false, Image::FORMAT_R8);

    bool inside = started_point.x < canvas_size.x && started_point.x >= 0 && started_point.y < canvas_size.y && started_point.y >= 0;
    if( !inside ){
        return nullptr;
    }

    int32_t locked_color = p_color_map->get_pixel(started_point.x, started_point.y).get_r8();


    PixelPenCPP::flood_fill_iterative(locked_color, started_point, p_color_map, image, grow_only_along_axis);

    if(mask_margin == Vector2i(0, 0)){
        return image;
    }

    Ref<Image> mask_image = Image::create(canvas_size.x + mask_margin.x * 2, canvas_size.y + mask_margin.y * 2, false, Image::FORMAT_R8);
    mask_image->blit_rect(image, Rect2i(Vector2i(), canvas_size), mask_margin);

    return mask_image;
}


void PixelPenCPP::flood_fill_iterative(
            int32_t reference_color,
            Vector2i start_point,
            const Ref<Image>  &p_color_map,
            const Ref<Image> &p_image,
            const bool grow_only_along_axis = false) {
    
    Vector2i canvas_size = p_color_map->get_size();
    std::queue<Vector2i> points_queue;
    points_queue.push(start_point);

    // Create a boolean matrix to track visited pixels
    std::vector<std::vector<bool>> visited(canvas_size.y, std::vector<bool>(canvas_size.x, false));

    while (!points_queue.empty()) {
        Vector2i current_point = points_queue.front();
        points_queue.pop();

        if (current_point.x < 0 || current_point.x >= canvas_size.x || current_point.y < 0 || current_point.y >= canvas_size.y) {
            continue; // Skip if out of bounds
        }

        if (visited[current_point.y][current_point.x]) {
            continue; // Skip if already visited
        }

        int32_t current_color = p_color_map->get_pixel(current_point.x, current_point.y).get_r8();
        if (current_color == reference_color && p_image->get_pixel(current_point.x, current_point.y).get_r8() == 0) {
            // Mark the pixel as visited
            visited[current_point.y][current_point.x] = true;
            
            Color c = Color(0, 0, 0, 0);
            c.set_r8(255);
            p_image->set_pixel(current_point.x, current_point.y, c);

            // Add neighboring points to the queue
            if (!grow_only_along_axis){
                points_queue.push(Vector2i(current_point.x - 1, current_point.y - 1));
                points_queue.push(Vector2i(current_point.x + 1, current_point.y - 1));
                points_queue.push(Vector2i(current_point.x + 1, current_point.y + 1));
                points_queue.push(Vector2i(current_point.x - 1, current_point.y + 1));
            }
            points_queue.push(Vector2i(current_point.x + 1, current_point.y));
            points_queue.push(Vector2i(current_point.x - 1, current_point.y));
            points_queue.push(Vector2i(current_point.x, current_point.y + 1));
            points_queue.push(Vector2i(current_point.x, current_point.y - 1));
        }
    }
}


Rect2i PixelPenCPP::get_mask_used_rect(const Ref<Image> &p_mask){
    Rect2i rect;
    int w = p_mask->get_width();
    int h = p_mask->get_height();
    rect.position = Vector2i(w, h);

    for (int x = 0; x < w; ++x) {
        for (int y = 0; y < h; ++y) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                rect.position.x = MIN(rect.position.x, x);
                break;
            }
        }
    }
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                rect.position.y = MIN(rect.position.y, y);
                break;
            }
        }
    }

    for (int x = w - 1; x >= 0; --x) {
        for (int y = h - 1; y >= 0; --y) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                Vector2i end = rect.get_end();
                end.x = MAX(rect.get_end().x, x);
                rect.set_end(end);
                break;
            }
        }
    }
    for (int y = h - 1; y >= 0; --y) {
        for (int x = w - 1; x >= 0; --x) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                Vector2i end = rect.get_end();
                end.y = MAX(rect.get_end().y, y);
                rect.set_end(end);
                break;
            }
        }
    }
    rect.size += Vector2i(1, 1);
    return rect;
}


bool PixelPenCPP::coor_inside_canvas(int x, int y, Vector2i size, const Ref<Image> &p_mask = nullptr){
	bool yes = x < size.x && x >= 0 && y < size.y && y >= 0;
    if(p_mask.is_valid()){
	    yes = yes && p_mask->get_pixel(x, y).get_r8() != 0;
    }
	return yes;
}


Ref<Image> PixelPenCPP::get_color_map_with_mask(const Ref<Image> &p_mask, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
    Rect2i rect = p_mask->get_used_rect();

    
    Ref<Image> image = Image::create(size.x, size.y, false, Image::FORMAT_R8);

    for (int y = rect.position.y; y < rect.get_end().y; y++) {
        for (int x = rect.position.x; x < rect.get_end().x; x++) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                image->set_pixel(x, y, p_color_map->get_pixel(x, y));
            }
        }
    }

    return image;
}


Ref<Image> PixelPenCPP::get_mask_from_polygon(const PackedVector2Array polygon, const Vector2i mask_size, const Vector2i mask_margin){
    Ref<Image> image = Image::create(mask_size.x + mask_margin.x * 2, mask_size.y + mask_margin.y * 2, false, Image::FORMAT_R8);
    for (int y = 0; y < mask_size.y; y++) {
        for (int x = 0; x < mask_size.x; x++) {
            if( PixelPenCPP::is_point_in_polygon(Vector2i(x, y), polygon) ){
                Color c = Color();
                c.set_r8(255);
                image->set_pixel(x + mask_margin.x, y + mask_margin.y, c);
            }
        }
    }
    return image;
}


void PixelPenCPP::empty_index_on_color_map(const Ref<Image> &p_mask, const Ref<Image> &p_color_map){
    Rect2i rect = p_mask->get_used_rect();

    for (int y = rect.position.y; y < rect.get_end().y; y++) {
        for (int x = rect.position.x; x < rect.get_end().x; x++) {
            if (p_mask->get_pixel(x, y).get_r8() != 0) {
                p_color_map->set_pixel(x, y, Color(0,0,0,0));
            }
        }
    }
}


void PixelPenCPP::blit_color_map(const Ref<Image> &p_src_map, const Ref<Image> &p_mask, Vector2i offset, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
    Rect2i src_rect = p_src_map->get_used_rect();

	Rect2i mask_rect;
    if (p_mask.is_valid()){
        mask_rect = p_mask->get_used_rect();
    }

    for (int y = 0; y < size.y; y++) {
        for (int x = 0; x < size.x; x++) {
            int _x = x - offset.x;
            int _y = y - offset.y;
            if (!PixelPenCPP::coor_inside_canvas(x, y, size) || !src_rect.has_point(Vector2i(_x, _y))) {
                continue;
            }
            bool yes = false;

            if (p_mask.is_null() || (mask_rect.has_point(Vector2i(_x, _y)) && p_mask->get_pixel(_x, _y).get_r8() != 0)) {
                Color color_index = p_src_map->get_pixel(_x, _y);
                if (color_index.get_r8() != 0) {
                    p_color_map->set_pixel(x, y, color_index);
                }
            }
            
        }
    }
}


void PixelPenCPP::swap_color(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map){
	Vector2i size = p_color_map->get_size();
    for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() == palette_index_a){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_b);
				p_color_map->set_pixel(x, y, c);
            }else if (p_color_map->get_pixel(x, y).get_r8() == palette_index_b){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_a);
				p_color_map->set_pixel(x, y, c);
            }
        }
    }
}


void PixelPenCPP::replace_color(const int32_t palette_index_from, const int32_t palette_index_to, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() == palette_index_from){
                Color c = Color(0,0,0,0);
                c.set_r8(palette_index_to);
				p_color_map->set_pixel(x, y, c);
            }
        }
    }
}


void PixelPenCPP::swap_palette(const PackedColorArray &old_palette, const PackedColorArray &new_palette, const Ref<Image> &p_color_map){
    Vector2i size = p_color_map->get_size();
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
            int32_t old_idx = p_color_map->get_pixel(x, y).get_r8();
            if(old_palette[old_idx] != new_palette[old_idx]){
                int32_t new_idx = new_palette.find(old_palette[old_idx]);
                Color c = Color(0,0,0,0);
                if(new_idx != -1){
                    c.set_r8(new_idx);
                }
                p_color_map->set_pixel(x, y, c);
                
            }
        }
    }
}


void PixelPenCPP::move_shift(const Vector2i direction, const Ref<Image> &p_image){
    Vector2i size = p_image->get_size();
    Ref<Image> crop = p_image->duplicate();
    bool r8 = p_image->get_format() == Image::FORMAT_R8;
    bool rf = p_image->get_format() == Image::FORMAT_RGBAF;
    for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
            int32_t x_shift = x + direction.x;
            int32_t y_shift = y + direction.y;
            bool outside = x_shift < 0 || x_shift >= size.x || y_shift < 0 || y_shift >= size.y;
            if(outside){
                continue;
            }
            if (r8){
                Color c = crop->get_pixel(x, y);
                if(c.get_r8() > 0){
                    p_image->set_pixel(x_shift, y_shift, c);
                }
            }else if (rf){
                Color c = crop->get_pixel(x, y);
                if(c.a > 0){
                    p_image->set_pixel(x_shift, y_shift, c);
                }
            }
        }
    }
}


void PixelPenCPP::blend(const Ref<Image> &p_target_image, const Ref<Image> &p_src_image, const Vector2i offset){
    Vector2i src_size = p_src_image->get_size();
    Vector2i target_size = p_target_image->get_size();
    bool r8 = p_src_image->get_format() == Image::FORMAT_R8;
    bool rf = p_src_image->get_format() == Image::FORMAT_RGBAF;
    for(int32_t y = 0; y < src_size.y; y++){
		for(int32_t x = 0; x < src_size.x; x++){
            int32_t x_shift = x + offset.x;
            int32_t y_shift = y + offset.y;
            bool outside = x_shift < 0 || x_shift >= target_size.x || y_shift < 0 || y_shift >= target_size.y;
            if(outside){
                continue;
            }
            if (r8){
                Color c = p_src_image->get_pixel(x, y);
                if(c.get_r8() > 0){
                    p_target_image->set_pixel(x_shift, y_shift, c);
                }
            }else if (rf){
                Color c = p_src_image->get_pixel(x, y);
                if(c.a > 0){
                    p_target_image->set_pixel(x_shift, y_shift, c);
                }
            }
        }
    }
}

// mask2_image can be null
void PixelPenCPP::fill_color(const Ref<Image> &p_mask1_image, const Ref<Image> &p_target_image, const Color color, const Ref<Image> &p_mask2_image){
    ERR_FAIL_COND_MSG(p_mask1_image->get_size() != p_target_image->get_size(), "p_mask1_image size must be the same with p_target_image size");
    int8_t mask2_format = -1;
    if(p_mask2_image.is_valid()){
        ERR_FAIL_COND_MSG(p_mask1_image->get_size() != p_mask2_image->get_size(), "p_mask1_image size must be the same with p_mask2_image size");
        mask2_format = (p_mask2_image->get_format() == Image::FORMAT_R8) ? 0 : (p_mask2_image->get_format() == Image::FORMAT_RGBA8 ? 1 : 2);
        ERR_FAIL_COND_MSG(mask2_format == 2 && p_mask2_image->get_format() != Image::FORMAT_RGBAF, "not supported p_mask2_image format");
    }
    int8_t mask1_format = (p_mask1_image->get_format() == Image::FORMAT_R8) ? 0 : (p_mask1_image->get_format() == Image::FORMAT_RGBA8 ? 1 : 2);
    ERR_FAIL_COND_MSG(mask1_format == 2 && p_mask1_image->get_format() != Image::FORMAT_RGBAF, "not supported p_mask1_image format");

    int8_t target_format = (p_target_image->get_format() == Image::FORMAT_R8) ? 0 : (p_target_image->get_format() == Image::FORMAT_RGBA8 ? 1 : 2);
    ERR_FAIL_COND_MSG(target_format == 2 && p_target_image->get_format() != Image::FORMAT_RGBAF, "not supported p_target_image format");

    Vector2i size = p_target_image->get_size();
    for(int32_t y = 0; y < size.y; y++){
	    for(int32_t x = 0; x < size.x; x++){
            if(mask2_format != -1){
                bool mask2_has_value = false;
                if(mask2_format == 0 && p_mask2_image->get_pixel(x, y).get_r8() != 0){
                    mask2_has_value = true;
                }else if(mask2_format == 1 && p_mask2_image->get_pixel(x, y).get_a8() != 0){
                    mask2_has_value = true;
                }else if(mask2_format == 2 && p_mask2_image->get_pixel(x, y).a != 0){
                    mask2_has_value = true;
                }
                if(!mask2_has_value){
                    continue;
                }
            }
            if(mask1_format == 0 && p_mask1_image->get_pixel(x, y).get_r8() != 0){
                p_target_image->set_pixel(x, y, color);
            }else if(mask1_format == 1 && p_mask1_image->get_pixel(x, y).get_a8() != 0){
                p_target_image->set_pixel(x, y, color);
            }else if(mask1_format == 2 && p_mask1_image->get_pixel(x, y).a != 0){
                p_target_image->set_pixel(x, y, color);
            }
        }
    }
}


void PixelPenCPP::fill_rect_outline(const Rect2i rect, const Color color, const Ref<Image> &p_target, const Ref<Image> &p_mask){
    int8_t target_format = (p_target->get_format() == Image::FORMAT_R8) ? 0 : (p_target->get_format() == Image::FORMAT_RGBA8 ? 1 : 2);
    ERR_FAIL_COND_MSG(target_format == 2 && p_target->get_format() != Image::FORMAT_RGBAF, "not supported p_target format");

    int8_t mask_format = -1;
    if(p_mask.is_valid()){
        ERR_FAIL_COND_MSG(p_target->get_size() != p_mask->get_size(), "p_target size must be the same with p_mask size");
        mask_format = (p_mask->get_format() == Image::FORMAT_R8) ? 0 : (p_mask->get_format() == Image::FORMAT_RGBA8 ? 1 : 2);
        ERR_FAIL_COND_MSG(mask_format == 2 && p_mask->get_format() != Image::FORMAT_RGBAF, "not supported p_mask format");
    }

    Rect2i bound_rect = Rect2i(0, 0, p_target->get_width(), p_target->get_height());
    Rect2i rect_abs = rect.abs();

    // Horizontal line
    std::vector<int32_t> vec_y = { rect_abs.position.y, rect_abs.get_end().y - 1 };
    for (int32_t y : vec_y){
        for(int32_t x = rect_abs.position.x; x < rect_abs.get_end().x; x++){
            if(bound_rect.has_point(Vector2i(x, y))){
                if(mask_format != -1){
                    bool mask_has_value = false;
                    if(mask_format == 0 && p_mask->get_pixel(x, y).get_r8() != 0){
                        mask_has_value = true;
                    }else if(mask_format == 1 && p_mask->get_pixel(x, y).get_a8() != 0){
                        mask_has_value = true;
                    }else if(mask_format == 2 && p_mask->get_pixel(x, y).a != 0){
                        mask_has_value = true;
                    }
                    if(!mask_has_value){
                        continue;
                    }
                }
                p_target->set_pixel(x, y, color);
            }
        } 
    }

    // Vertical line
    std::vector<int32_t> vec_x = { rect_abs.position.x, rect_abs.get_end().x - 1 };
    for (int32_t x : vec_x){
        for(int32_t y = rect_abs.position.y; y < rect_abs.get_end().y; y++){
            if(bound_rect.has_point(Vector2i(x, y))){
                if(mask_format != -1){
                    bool mask_has_value = false;
                    if(mask_format == 0 && p_mask->get_pixel(x, y).get_r8() != 0){
                        mask_has_value = true;
                    }else if(mask_format == 1 && p_mask->get_pixel(x, y).get_a8() != 0){
                        mask_has_value = true;
                    }else if(mask_format == 2 && p_mask->get_pixel(x, y).a != 0){
                        mask_has_value = true;
                    }
                    if(!mask_has_value){
                        continue;
                    }
                }
                p_target->set_pixel(x, y, color);
            }
        } 
    }

}


void PixelPenCPP::clean_invisible_color(const Ref<Image> &p_color_map, const PackedColorArray &palette){
    ERR_FAIL_COND_MSG(p_color_map->get_format() != Image::FORMAT_R8, "not supported p_color_map format");

    Vector2i layer_size = p_color_map->get_size();
    int64_t p_size = palette.size();

    for(int32_t y = 0; y < layer_size.y; y++){
		for(int32_t x = 0; x < layer_size.x; x++){
            int32_t index = p_color_map->get_pixel(x, y).get_r8();
            if ( index != 0 && index < p_size){
                Color color = palette[index];
                if( color.a == 0 ){
                    Color new_color = Color();
                    new_color.set_r8(0);
                    p_color_map->set_pixel(x, y, new_color);
                }
            }
            
        }
    }
}


PackedColorArray PixelPenCPP::import_image(const Ref<Image> &p_layer_image, const Ref<Image> &p_imported_image, const PackedColorArray palette){
    PackedColorArray returned_palette = palette;
    Vector2i layer_size = p_layer_image->get_size();
    Vector2i imported_size = p_imported_image->get_size();
    for(int32_t y = 0; y < layer_size.y; y++){
		for(int32_t x = 0; x < layer_size.x; x++){
			if (x < imported_size.x && y < imported_size.y){
                Color color = p_imported_image->get_pixel(x, y);
                if(color.a == 0){
                    continue;
                }
                int32_t palette_index = returned_palette.find(color);
                if (palette_index == -1){
                    palette_index = 0;
                    for(int32_t i = 1; i < returned_palette.size();  i++){
                        if(returned_palette[i].a == 0){
                            palette_index = i;
                            returned_palette[i] = color;
                            break;
                        }
                    }
                }
                if(palette_index != 0){
                    Color c = Color(0,0,0,0);
                    c.set_r8(palette_index);
                    p_layer_image->set_pixel(x, y, c);
                }
            }
        }
    }
    return returned_palette;
}


Ref<Image> PixelPenCPP::get_image(PackedColorArray palette_color, const Ref<Image> &p_color_map, const bool mipmap){
	Vector2i size = p_color_map->get_size();
    Ref<Image> cache_image = Image::create(size.x, size.y, mipmap, Image::FORMAT_RGBAF);

	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() != 0){
				cache_image->set_pixel(x, y, palette_color[p_color_map->get_pixel(x, y).get_r8()]);
            }
        }
    }
	return cache_image;
}


Ref<Image> PixelPenCPP::get_image_with_mask(PackedColorArray palette_color, const Ref<Image> &p_color_map, const Ref<Image> &p_mask, const bool mipmap){
	Vector2i size = p_color_map->get_size();
    Ref<Image> cache_image = Image::create(size.x, size.y, mipmap, Image::FORMAT_RGBAF);

	int32_t i  = 0;
	for(int32_t y = 0; y < size.y; y++){
		for(int32_t x = 0; x < size.x; x++){
			if (p_color_map->get_pixel(x, y).get_r8() != 0 && p_mask->get_pixel(x, y).get_r8() != 0){
				cache_image->set_pixel(x, y, palette_color[p_color_map->get_pixel(x, y).get_r8()]);
            }
        }
    }
	return cache_image;
}

// Steal from godot source code since don't know how to use `Geometry2D::is_point_in_polygon`
bool PixelPenCPP::is_point_in_polygon(const Vector2 &p_point, const PackedVector2Array &p_polygon) {
	int c = p_polygon.size();
	if (c < 3) {
		return false;
	}
	const Vector2 *p = p_polygon.ptr();
	Vector2 further_away(-1e20, -1e20);
	Vector2 further_away_opposite(1e20, 1e20);

	for (int i = 0; i < c; i++) {
		further_away = further_away.max(p[i]);
		further_away_opposite = further_away_opposite.min(p[i]);
	}

	// Make point outside that won't intersect with points in segment from p_point.
	further_away += (further_away - further_away_opposite) * Vector2(1.221313, 1.512312);

	int intersections = 0;
	for (int i = 0; i < c; i++) {
		const Vector2 &v1 = p[i];
		const Vector2 &v2 = p[(i + 1) % c];

		Vector2 res;
		if (PixelPenCPP::segment_intersects_segment(v1, v2, p_point, further_away, &res)) {
			intersections++;
			if (res.is_equal_approx(p_point)) {
				// Point is in one of the polygon edges.
				return true;
			}
		}
	}

	return (intersections & 1);
}

// Steal from godot source code since don't know how to use `Geometry2D::is_point_in_polygon`
bool PixelPenCPP::segment_intersects_segment(const Vector2 &p_from_a, const Vector2 &p_to_a, const Vector2 &p_from_b, const Vector2 &p_to_b, Vector2 *r_result) {
    Vector2 B = p_to_a - p_from_a;
    Vector2 C = p_from_b - p_from_a;
    Vector2 D = p_to_b - p_from_a;

    real_t ABlen = B.dot(B);
    if (ABlen <= 0) {
        return false;
    }
    Vector2 Bn = B / ABlen;
    C = Vector2(C.x * Bn.x + C.y * Bn.y, C.y * Bn.x - C.x * Bn.y);
    D = Vector2(D.x * Bn.x + D.y * Bn.y, D.y * Bn.x - D.x * Bn.y);

    // Fail if C x B and D x B have the same sign (segments don't intersect).
    if ((C.y < (real_t)-CMP_EPSILON && D.y < (real_t)-CMP_EPSILON) || (C.y > (real_t)CMP_EPSILON && D.y > (real_t)CMP_EPSILON)) {
        return false;
    }

    // Fail if segments are parallel or colinear.
    // (when A x B == zero, i.e (C - D) x B == zero, i.e C x B == D x B)
    if (Math::is_equal_approx(C.y, D.y)) {
        return false;
    }

    real_t ABpos = D.x + (C.x - D.x) * D.y / (D.y - C.y);

    // Fail if segment C-D crosses line A-B outside of segment A-B.
    if ((ABpos < 0) || (ABpos > 1)) {
        return false;
    }

    // Apply the discovered position to line A-B in the original coordinate system.
    if (r_result) {
        *r_result = p_from_a + B * ABpos;
    }

    return true;
}
