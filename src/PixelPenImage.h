#ifndef PIXELPENIMAGE_H
#define PIXELPENIMAGE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot{

    class PixelPenImage : public RefCounted{
        GDCLASS(PixelPenImage, RefCounted)

        private:
            Ref<Image> _image;
            Ref<Image> _mask;
            bool _use_mask;
            std::vector<Ref<Image>> _brush;
            

        protected:
            static void _bind_methods();


        public:
            PixelPenImage();
            ~PixelPenImage();
            void add_brush(const Ref<Image> &p_image);
            void remove_brush(int32_t index);
            Ref<Image> get_brush(int32_t index);
            int32_t get_brush_count();
            void clear_brush();
            void set_image(const Ref<Image> &p_image);
            Ref<Image> get_image();
            void set_mask(const Ref<Image> &p_image);
            Ref<Image> get_mask();
            bool set_pixel(int32_t x, int32_t y, const Color &color, int32_t brush_index);
    };

}

#endif
 