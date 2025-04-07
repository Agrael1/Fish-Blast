module;
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/input.hpp>
export module fb.player;

namespace fb {
using namespace godot;
export class PlayerControl : public CharacterBody2D
{
    GDCLASS(PlayerControl, CharacterBody2D);

private:
    static constexpr float SPEED = 200.0f;
    static constexpr float ACCELERATION = 200.0f;
    
public:
    static void _bind_methods()
    {

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
};
} // namespace fb