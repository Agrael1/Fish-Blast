module;
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/camera2d.hpp>
#include <cmath>
#include <random>
export module fb.player;

namespace fb {
using namespace godot;
export class CameraController : public Camera2D
{
    GDCLASS(CameraController, Camera2D);

public:
    static void _bind_methods()
    {
        ClassDB::bind_method(D_METHOD("set_random_strength", "strength"), &CameraController::set_random_strength);
        ClassDB::bind_method(D_METHOD("get_random_strength"), &CameraController::get_random_strength);
        ClassDB::bind_method(D_METHOD("set_shake_fade", "fade"), &CameraController::set_shake_fade);
        ClassDB::bind_method(D_METHOD("get_shake_fade"), &CameraController::get_shake_fade);

        ClassDB::add_property(get_class_static(), PropertyInfo(Variant::FLOAT, "random_strength"), "set_random_strength", "get_random_strength");
        ClassDB::add_property(get_class_static(), PropertyInfo(Variant::FLOAT, "shake_fade"), "set_shake_fade", "get_shake_fade");
    }

    void _process(double delta) override
    {
        if (_shake_strength > 0.0f) {
            _shake_strength = std::lerp(_shake_strength, 0.0f, _shake_fade * delta);

            Vector2 offset = get_shake_offset();
            set_offset(get_offset() + offset);
        }
    }
    void apply_shake(float strength)
    {
        _shake_strength = strength;
    }

    void set_random_strength(float strength)
    {
        _random_strength = strength;
    }
    float get_random_strength() const
    {
        return _random_strength;
    }
    void set_shake_fade(float fade)
    {
        _shake_fade = fade;
    }
    float get_shake_fade() const
    {
        return _shake_fade;
    }

    Vector2 get_shake_offset()
    {
        return Vector2(
                std::uniform_real_distribution<float>(-_random_strength, _random_strength)(_rng),
                std::uniform_real_distribution<float>(-_random_strength, _random_strength)(_rng));
    }

private:
    float _random_strength = 0.0f;
    float _shake_fade = 1.0f;
    float _shake_strength = 0.0f;
    std::mt19937 _rng{ std::random_device{}() };
};

export class CameraFollowTargetX : public Node2D
{
    GDCLASS(CameraFollowTargetX, Node2D);

public:
    static void _bind_methods()
    {
        ClassDB::bind_method(D_METHOD("get_priority"), &CameraFollowTargetX::get_priority);
        ClassDB::bind_method(D_METHOD("set_priority", "priority"), &CameraFollowTargetX::set_priority);
        ClassDB::add_property(get_class_static(), PropertyInfo(Variant::INT, "priority"), "set_priority", "get_priority");
    }

public:
    int get_priority() const
    {
        return _priority;
    }
    void set_priority(int priority)
    {
        _priority = priority;
    }

private:
    int _priority = 0;
};

export class PlayerControl : public CharacterBody2D
{
    GDCLASS(PlayerControl, CharacterBody2D);

private:
    static constexpr float SPEED = 200.0f;
    static constexpr float ACCELERATION = 200.0f;

public:
    static void _bind_methods()
    {
        ClassDB::bind_method(D_METHOD("set_camera", "camera"), &PlayerControl::set_camera);
        ClassDB::bind_method(D_METHOD("get_camera"), &PlayerControl::get_camera);
        ClassDB::bind_method(D_METHOD("_on_hitbox_body_entered", "area"), &PlayerControl::_on_hitbox_body_entered);

        ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "camera"), "set_camera", "get_camera");
    }

    void _ready() override
    {
        hitbox = get_node<Area2D>("HitboxArea");
        if (hitbox) {
            hitbox->connect("area_entered", { this, "_on_hitbox_body_entered" });
        }
    }

    void _physics_process(double delta) override
    {
        auto* input = Input::get_singleton();
        auto direction_lr = input->get_axis("move_left", "move_right");
        auto direction_ud = input->get_axis("move_up", "move_down");
        Vector2 direction = Vector2(direction_lr, direction_ud).normalized();
        set_velocity(get_velocity().move_toward(direction * SPEED, ACCELERATION));

        move_and_slide();
    }

    void _on_hitbox_body_entered(Area2D* area)
    {
        if (camera) {
            camera->apply_shake(4);
        }
    }
    void set_camera(const NodePath& cam)
    {
        camera = get_node<CameraController>(cam);
    }
    NodePath get_camera() const
    {
        if (!camera) {
            return NodePath();
        }
        return camera->get_path();
    }

private:
    Area2D* hitbox = nullptr;
    CameraController* camera = nullptr;
};
} // namespace fb