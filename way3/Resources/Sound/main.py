import pygame, time
import curses as c
from sound import Sound

window = c.initscr()
pygame.init()

sound = Sound()
sound.load_sound('song', 'music.ogg')
sound.set_volume('song', 0.8)
sound.loop_sound('song')
sound.load_sound('blip', 'sfx-blipmale.wav')
sound.set_volume('blip', 0.5)

dialogue = [
    "I was going door-to-door,#|selling subscriptions when I saw|a man fleeing an apartment.",
    "I thought he must be in a|hurry because he left the|door half-open behind him.",
    "Thinking it strange,## I looked|inside the apartment.",
    "Then I saw her lying there...##$|A woman...## not moving...##% dead!",
    "I quailed in fright and found|myself unable to go inside.",
    "I thought to call the police|immediately!",
    "However, the phone in her|apartment wasn't working.",
    "I went to a nearby park and|found a public phone.",
    "I remember the time exactly:##|It was 1:00 PM.",
    "The man who ran was,# without|a doubt,# the defendant sitting|right over there.",
]

def add(y,x,c):
    try:
        window.addstr(y, x, c)
        window.refresh()
    except:
        return
    
def main(foo):
    c.curs_set(0)
    c.start_color()
    c.use_default_colors()
    c.init_pair(1, c.COLOR_RED, c.COLOR_BLACK)
    
    #text = "but that clock was soon going to be at the center of another incident."
    #text = "It sounds like|he wants to die..."
    #text = "I was going door-to-door,|selling subscriptions when I saw|a man fleeing an apartment."
    # I was going door-to-door,
    # selling subscriptions when I saw
    # a man fleeing an apartment.
    fast = 0.06
    slow = 0.09
    speed = fast
    
    # I_t_? s_o_u_n_d_s_? l_i_k_e_ h_e_ w_a_n_t_s_? t_o_? d_i_e_._._._
    # ..._  ..._..._..._  ..._..._..._  ..._..._  ..._  ..._..._..._
    # 1 3 3 2 1 3

    for text in dialogue:
        window.clear()
        x,y = 0,1
        debug = True
        
        odd = False
        for letter in text:
            odd = not odd
            if letter not in ' |#$%':
                add(y, x, letter)
                if odd:
                    sound.play_sound('blip')
                    if debug:
                        add(y+1, x, '!')
            else:
                if letter == '$':
                    speed = slow
                    if debug:
                        add(y, x, '<slow>')
                        x += 5
                    else:
                        x -= 1
                if letter == '%':
                    speed = fast
                    if debug:
                        add(y, x, '<fast>')
                        x += 5
                    else:
                        x -= 1
                if letter == '#':
                    time.sleep(speed)
                    if debug:
                        add(y, x, '#')
                        add(y, x+1, '#')
                        x += 1
                    else:
                        x -= 1
                if letter == '|':
                    y += 1 + debug
                    x = -1
                if not odd:
                    if debug:
                        x += 1
                        add(y, x, ' ')
                    time.sleep(speed/2)
                odd = False
            time.sleep(speed/2)
            x += 1

        window.getch()

c.wrapper(main)

