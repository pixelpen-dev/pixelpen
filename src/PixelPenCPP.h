#ifndef PIXELPENCPP_H
#define PIXELPENCPP_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot{

    class PixelPenCPP : public RefCounted{
        GDCLASS(PixelPenCPP, RefCounted)

        private:
            void flood_fill_iterative(int32_t reference_color, Vector2i start_point, const Ref<Image> &p_color_map, const Ref<Image> &p_image, const bool grow_only_along_axis);
            

        protected:
            static void _bind_methods();


        public:
            PixelPenCPP();
            ~PixelPenCPP();
            String version();
            Ref<Image> get_image_flood(Vector2i started_point, const Ref<Image> &p_src_image, Vector2i mask_margin, const bool grow_only_along_axis);
            Rect2i get_mask_used_rect(const Ref<Image> &p_mask);
            bool coor_inside_canvas(int x, int y, Vector2i size, const Ref<Image> &p_mask);
            Ref<Image> get_color_map_with_mask(const Ref<Image> &p_mask, const Ref<Image> &p_color_map);
            Ref<Image> get_mask_from_polygon(const PackedVector2Array polygon, const Vector2i mask_size, const Vector2i mask_margin);
            void empty_index_on_color_map(const Ref<Image> &p_mask, const Ref<Image> &p_color_map);
            void blit_color_map(const Ref<Image> &p_src_map, const Ref<Image> &p_mask, Vector2i offset, const Ref<Image> &p_color_map);
            void swap_color(const int32_t palette_index_a, const int32_t palette_index_b, const Ref<Image> &p_color_map);
            void replace_color(const int32_t palette_index_from, const int32_t palette_index_to, const Ref<Image> &p_color_map);
            void swap_palette(const PackedColorArray &old_palette, const PackedColorArray &new_palette, const Ref<Image> &p_color_map);
            void move_shift(const Vector2i direction, const Ref<Image> &p_image);
            void blend(const Ref<Image> &p_target_image, const Ref<Image> &p_src_image, const Vector2i offset);
            void fill_color(const Ref<Image> &p_mask1_image, const Ref<Image> &p_target_image, const Color color, const Ref<Image> &p_mask2_image);
            void fill_rect_outline(const Rect2i rect, const Color color, const Ref<Image> &p_target, const Ref<Image> &p_mask);
            void clean_invisible_color(const Ref<Image> &p_color_map, const PackedColorArray &palette);
            PackedColorArray import_image(const Ref<Image> &p_layer_image, const Ref<Image> &p_imported_image, const PackedColorArray palette);
            Ref<Image> get_image(PackedColorArray palette_color, const Ref<Image> &p_color_map, const bool mipmap);
            Ref<Image> get_image_with_mask(PackedColorArray palette_color, const Ref<Image> &p_color_map, const Ref<Image> &p_mask, const bool mipmap);
    };

}

#endif
 