# WIP
![usage preview](/media/usage.gif)

## description
Vim-like music player inspired by cmus and ranger.

## motivation
To combine cmus and ranger functionality with a nice-looking interface.

## installation
git clone https://github.com/0x1869f/dumb-player  
cd dumb-player  
yarn install  
yarn run build  

## usage
run current release binary  
./release/0.0.1/linux-unpacked/dumb-player  

## supported formats
mp3, flac

## key bindings
### File manager
- **O** - open
- **i/space** - mark/unmark current
- **o/enter** - select marked
- **jk** - navigation
- **ctrl+f** - jump to next screen
- **ctrl+b** - jump to previous screen
- **gg** - jump to start
- **G** - jump to end
- **l** - open directory
- **h** - previous directory
- **/** - open filter
- **u** - clear filter
- **q/esq** - close

### Playlist
- **ctrl+l** - clear
- **jk** - navigation
- **ctrl+f** - jump to next screen
- **ctrl+b** - jump to previous screen
- **gg** - jump to start
- **G** - jump to end
- **dd** - remove selected
- **i/enter** - play selected
- **/** - open filter
- **u** - clear filter

### Player
- **n** - play next
- **p** - play previous
- **c** - pause/play
- **r** - switch random
- **m** - mute/unmute
- **=** - volume +5
- **+** - volume +10
- **-** - volume -5
- **_** - volume -10
- **L** - rewind forward
- **H** - rewind backward

### Filter
bash-like navigation
- **n** - history next
- **p** - history previous
- **ctrl+b/arrow left** - cursor back
- **ctrl+f/arrow right** - cursor forward
- **ctrl+h/backslash** - remove previous
- **ctrl+d/delete** - remove next
- **ctrl+u** - remove to start
- **ctrl+k** - remove to end
- **ctrl+y** - paste from buffer
- **ctrl+w** - remove previous word
- **ctrl+a** - jump to start
- **ctrl+e** - jump to end
- **alt+f/ctrl+arrow right** - jump to next word
- **alt+b/ctrl+arrow left** - jump to previous word
- **alt+b/ctrl+arrow left** - jump to previous word
- **esq** - close without saving
- **ctrl+c** - clear and close
- **enter** - save and close

## remote control
through unix socket  
check that $XDG_RUNTIME_DIR is set

### example
echo play-next | ncat -U $XDG_RUNTIME_DIR/dumb-player

### commands
play-next  
play-previous  
pause-or-play  
increase-volume  
decrease-volume  

