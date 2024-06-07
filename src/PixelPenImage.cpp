#include "PixelPenImage.h"
#include "PixelPenCPP.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;


Ref<Image> _image;
Ref<Image> _mask;
bool _use_mask = false;
std::vector<Ref<Image>> _brush;


PixelPenImage::PixelPenImage(){
}

PixelPenImage::~PixelPenImage(){
}


void PixelPenImage::add_brush(const Ref<Image> &p_image){
    _brush.push_back(p_image);
}


void PixelPenImage::remove_brush(int32_t index){
    _brush.erase(_brush.begin() + index);
}


Ref<Image> PixelPenImage::get_brush(int32_t index){
    if(index < _brush.size() && index >= 0){
        return _brush[index];
    }
    return nullptr;
}


int32_t PixelPenImage::get_brush_count(){
    return _brush.size();
}


void PixelPenImage::clear_brush(){
    _brush.clear();
}


void PixelPenImage::set_image(const Ref<Image> &p_image){
    ERR_FAIL_COND_MSG(p_image->get_format() != Image::FORMAT_R8, "not supported image format");
    _image = p_image;
}


Ref<Image> PixelPenImage::get_image(){
    if(!_image.is_valid()){
        return nullptr;
    }
    return _image;
}


void PixelPenImage::set_mask(const Ref<Image> &p_image){
    if(!p_image.is_valid()){
        _use_mask = false;
        return;
    }
    ERR_FAIL_COND_MSG(p_image->get_format() != Image::FORMAT_R8, "not supported image format");
    ERR_FAIL_COND_MSG(p_image->get_size() != _image->get_size(), "mask size must be the same with image size");
    _mask = p_image;
    _use_mask = true;
}


Ref<Image> PixelPenImage::get_mask(){
    if(!_mask.is_valid() || !_use_mask){
        return nullptr;
    }
    return _mask;
}


bool PixelPenImage::set_pixel(int32_t x, int32_t y, const Color &color, int32_t brush_index){

    Ref<Image> brush = get_brush(brush_index);
    if(brush.is_null()){
        return false;
    }

    Rect2i bound = Rect2i(Vector2i(), _image->get_size());

    for(int32_t j = 0; j < brush->get_height(); j++){
        for(int32_t i = 0; i < brush->get_width(); i++){
            if(brush->get_pixel(i, j).get_r8() == 0){
                continue;
            }

            Vector2i point = Vector2i(i + x, j + y) - (brush->get_size() / 2);
            if( !bound.has_point(point)){
                continue;
            }
            if(_use_mask){
                if(_mask->get_pixelv(point).get_r8() == 0){
                    continue;
                }
            }
            _image->set_pixelv(point, color);
        }
    }

    return true;

}


void PixelPenImage::_bind_methods(){
    ClassDB::bind_method(D_METHOD("add_brush", "p_image"), &PixelPenImage::add_brush);
    ClassDB::bind_method(D_METHOD("remove_brush", "index"), &PixelPenImage::remove_brush);
    ClassDB::bind_method(D_METHOD("get_brush", "index"), &PixelPenImage::get_brush);
    ClassDB::bind_method(D_METHOD("get_brush_count"), &PixelPenImage::get_brush_count);
    ClassDB::bind_method(D_METHOD("clear_brush"), &PixelPenImage::clear_brush);
    ClassDB::bind_method(D_METHOD("set_image", "p_image"), &PixelPenImage::set_image);
    ClassDB::bind_method(D_METHOD("get_image"), &PixelPenImage::get_image);
    ClassDB::bind_method(D_METHOD("set_mask", "p_image"), &PixelPenImage::set_mask);
    ClassDB::bind_method(D_METHOD("get_mask"), &PixelPenImage::get_mask);
    ClassDB::bind_method(D_METHOD("set_pixel", "x", "y", "color", "brush_index"), &PixelPenImage::set_pixel);
}
