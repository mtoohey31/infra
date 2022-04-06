from os.path import expanduser, join
from os import environ
from sys import platform
from subprocess import Popen
import json

term_program = "kitty"

command_prefix_list = ['fish', '-c']
if platform == 'darwin':
    command_prefix_string = f'{term_program} --title "floatme" -o background_opacity=0.8 -e '
elif 'SWAYSOCK' in environ:
    command_prefix_string = f'{term_program} --title "floatme" -o background_opacity=0.8 -e '
else:
    command_prefix_string = ''

with open(join(expanduser('~'), ".cache/wal/colors.json")) as file:
    pywal = json.load(file)

# Misc
c.statusbar.show = 'never'
c.auto_save.session = True
c.editor.command = command_prefix_list + \
    [command_prefix_string +
        'fish -c \'cat ".cache/wal/sequences" && $EDITOR {file}\'']
c.content.fullscreen.window = True
c.tabs.show = 'switching'
c.tabs.show_switching_delay = 1500
c.tabs.last_close = 'close'
c.completion.height = '25%'
c.content.headers.do_not_track = None
c.downloads.location.directory = '~/'
c.downloads.location.remember = False
c.hints.chars = 'asdfghjkl;qwertyuiopzxcvbnm'
c.tabs.title.format = '{current_title}'
c.url.start_pages = ['about:blank']
c.content.javascript.can_access_clipboard = True

# Keybinds
config.bind('m', 'spawn --userscript view_in_mpv')
config.bind('M', 'hint links spawn --userscript view_in_mpv {hint-url}')
config.bind('D', 'close')
config.bind('so', 'config-source')
config.bind('e', 'edit-url')
config.bind('(', 'jseval --world=main -f ~/.config/qutebrowser/js/slowDown.js')
config.bind(')', 'jseval --world=main -f ~/.config/qutebrowser/js/speedUp.js')
config.bind(
    'c-', 'jseval --world=main -f ~/.config/qutebrowser/js/zoomOut.js')
config.bind(
    'c+', 'jseval --world=main -f ~/.config/qutebrowser/js/zoomIn.js')
config.bind('wp', 'hint links spawn ~/.scripts/random_bg -l {hint-url}')
config.bind('<ESC>', 'fake-key <ESC>')
config.bind('<Ctrl-Shift-c>', 'yank selection')
config.bind('v', 'hint all hover')
config.bind('V', 'mode-enter caret')
config.bind('<Ctrl-F>', 'hint --rapid all tab-bg')
config.bind('<Ctrl-e>', 'fake-key <Ctrl-a><Ctrl-c><Ctrl-Shift-e>')
config.unbind('<Ctrl-v>')
config.unbind('<Ctrl-a>')

config.bind('o', 'set statusbar.show always;; set-cmd-text -s :open')
config.bind('O', 'set statusbar.show always;; set-cmd-text -s :open -t')
config.bind(':', 'set statusbar.show always;; set-cmd-text :')
config.bind('/', 'set statusbar.show always;; set-cmd-text /')
config.bind(
    '<Escape>', 'mode-enter normal;; set statusbar.show never', mode='command')
config.bind(
    '<Return>', 'command-accept;; set statusbar.show never', mode='command')

# Theming
c.fonts.default_size = '12pt'
c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.web.family.standard = 'SF Pro Text'
c.fonts.web.family.sans_serif = 'SF Pro Text'
c.fonts.web.family.serif = 'New York'
c.fonts.web.family.fixed = 'JetBrainsMono Nerd Font'

# TODO: make this dynamic based on sunset/sunrise with https://pypi.org/project/suntime/
c.colors.webpage.preferred_color_scheme = 'dark'
config.source(join(expanduser('~'), '.config/qutebrowser/qutewal/qutewal.py'))

c.url.searchengines = {'DEFAULT':
                       'https://duckduckgo.com/?q={}&kt=SF+Pro+Text&kj=' +
                       pywal['colors']['color2'] + '&k7=' +
                       pywal['special']['background'] + '&kx=' +
                       pywal['colors']['color1'] + '&k8' +
                       pywal['special']['foreground'] + '&k9' +
                       pywal['colors']['color2'] + '&kaa' +
                       pywal['colors']['color2'] + '&kae=d'}

# Fileselect
config.set('fileselect.handler', "external")
c.fileselect.single_file.command = command_prefix_list + \
    [command_prefix_string +
        'fish -c \'cat ".cache/wal/sequences" && lf -command "map <enter> \\${{echo \\"\\$f\\" > {}; lf -remote \\"send \\$id quit\\"}}"\'']
c.fileselect.multiple_files.command = command_prefix_list + \
    [command_prefix_string +
        'fish -c \'cat ".cache/wal/sequences" && lf -command "map <enter> \\${{echo \\"\\$fx\\" > {}; lf -remote \\"send \\$id quit\\"}}"\'']
c.fileselect.folder.command = command_prefix_list + \
    [command_prefix_string +
        'fish -c \'cat ".cache/wal/sequences" && lf -command "set dironly; map <enter> \\${{echo \\"\\$f\\" > {}; lf -remote \\"send \\$id quit\\"}}"\'']
