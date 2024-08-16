#ifndef PIXELPENCPP_H
#define PIXELPENCPP_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot{

    class PixelPenCPP : public RefCounted{
        GDCLASS(PixelPenCPP, RefCounted)

        private:
            static void flood_fill_iterative(int32_t reference_color, Vector2i start_point, const Ref<Image> &p_color_map, const Ref<Image> &p_image, const bool grow_only_along_axis);
            static bool is_point_in_polygon(const Vector2 &p_point, const PackedVector2Array &p_polygon);
            static bool segment_intersects_segment(const Vector2 &p_from_a, const Vector2 &p_to_a, const Vector2 &p_from_b, const Vector2 &p_to_b, Vector2 *r_result);

        protected:
            static void _bind_methods();


        public:
            PixelPenCPP();
            ~PixelPenCPP();
            static Ref<Image> get_image_flood(Vector2i started_point, const Ref<Image> &p_src_image, Vector2i mask_margin, const bool grow_only_along_axis);
            static Rect2i get_mask_used_rect(const Ref<Image> &p_mask);
            static bool coor_inside_canvas(int x, int y, Vector2i size, const Ref<Image> &p_mask);
            static Ref<Image> get_color_map_with_mask(const Ref<Image> &p_mask, const Ref<Image> &p_color_map);
            static Ref<Image> get_mask_from_polygon(const PackedVector2Array polygon, const Vector2i mask_size, const Vector2i mask_margin);
            static void empty_index_on_color_map(const Ref<Image> &p_mask, const Ref<Image> &p_color_map);
            static void blit_color_map(const Ref<Image> &p_src_map, const Ref<Image> &p_mask, Vector2i offset, const Ref<Image> &p_color_map);
            static void swap_color(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map);
            static void replace_color(const int32_t palette_index_from, const int32_t palette_index_to, const Ref<Image> &p_color_map);
            static void swap_palette(const PackedColorArray &old_palette, const PackedColorArray &new_palette, const Ref<Image> &p_color_map);
            static void move_shift(const Vector2i direction, const Ref<Image> &p_image);
            static void blend(const Ref<Image> &p_target_image, const Ref<Image> &p_src_image, const Vector2i offset);
            static void fill_color(const Ref<Image> &p_mask1_image, const Ref<Image> &p_target_image, const Color color, const Ref<Image> &p_mask2_image);
            static void fill_rect_outline(const Rect2i rect, const Color color, const Ref<Image> &p_target, const Ref<Image> &p_mask);
            static void clean_invisible_color(const Ref<Image> &p_color_map, const PackedColorArray &palette);
            static PackedColorArray import_image(const Ref<Image> &p_layer_image, const Ref<Image> &p_imported_image, const PackedColorArray palette);
            static Ref<Image> get_image(PackedColorArray palette_color, const Ref<Image> &p_color_map, const bool mipmap);
            static Ref<Image> get_image_with_mask(PackedColorArray palette_color, const Ref<Image> &p_color_map, const Ref<Image> &p_mask, const bool mipmap);
    };

}

#endif
 