[7,//a #major third
2,//b
2,//c
11,//d
5,//e #1
12,//f
11,//g
0,//h
9,//i
0,//j
0,//k
3,//l
4,//m
0,//n
7,//o
-1,//p
-1,//q
5,//r
6,//s
4,//t  #2
4,//u
-13,//v
9,//w
-1,//x
11,//y
0//z
] @=> int alpha[];

// HID
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// patch
BeeThree organ => JCRev r => Echo e => dac;

//Echo e2 => 
// set delays
0::ms => e.delay;
1::second => e.max;
//480::ms => e2.max => e2.delay;
// set gains
.6 => e.mix;
//.3 => e2.mix;
.9 => organ.gain;

[20,32,32,32,20,20] @=>int keys[];
0 => int keyIndex;
keys[0] => int key; //E or something cool like that I think

.6=> float eT;
//.3=> float e2T;
.6=> float eCur;
//.3=> float e2Cur;

spork ~ fadeNice();

// infinite event loop
while( true )
{
    // wait for event
    hi => now;
    // get message
    while( hi.recv( msg ) )
    {
        // check
        if( msg.isButtonDown() )
        {
            0 => float freq;
            <<<msg.which>>>;
            
            if(msg.which < 30){
                //we are alpha character
                Std.mtof(alpha[msg.which-4]+key) => freq;
            }else if(msg.which==40){
                //Enter key I think?
                keyIndex++;
                keys[keyIndex%keys.cap()]=>key;
            }else if(msg.which == 229){
                //shift
                1 => eT;
            }else if(msg.which == 231){
                //comand
                1 => eT;
            }else if(msg.which == 230){
                //option
                .5 => eT;
            }else if(msg.which == 55){
                // period
                spork ~ punctuate(key,0);
            }else if(msg.which == 56){
                // ?
                spork ~ punctuate(key,1);
            }else if(msg.which == 30){
                //!
                spork ~ punctuate(key, 2);
            }else if(msg.which == 54){
                //,
                spork ~ punctuate(key, 3);
            }
            if(freq!=0){
                freq => organ.freq;
                1 => organ.gain;
                1 => organ.noteOn;
                80::ms => now; 
            }
            
        }
        else
        {
            if(msg.isButtonUp() && (msg.which == 229)){
                .6 => eT;
                //.3 => e2T;
                <<<msg.which>>>;
            }else{
                0 => organ.noteOff;
            }
        }
    }
}

fun void punctuate(int thisKey, int style)
{
    // 0 -> .
    // 1 -> ?
    // 2 -> ! (1)
    // 3 -> ,
    .1=> float startGain;
    SinOsc s => JCRev rd => dac;
    startGain=>s.gain;
    
    if(style ==0 || style == 1){
        [0] @=> int chord[];
        if(style == 0){
            [4,7,12] @=> chord;
        }else if(style == 1) {
            [3,6,9,12] @=> chord;
        }
        0=> int i;
        for( i; i<2 ; 1+=>i){
            0=> int j;
            for(j; j<chord.cap(); 1+=>j){
                Std.mtof(thisKey + 12*i + chord[j]) => s.freq;
                120::ms => now;
            }
        } 
    }else if (style == 2){
        Std.mtof(thisKey) => float bassFreq;
        1=> int i;
        for( i; i<13; 1+=>i){
            bassFreq * i => s.freq;
            120::ms => now;
        }
    }else if (style == 3){
        Std.mtof(thisKey) *12 => s.freq;
    }
    
    0=> int i;
    startGain => float sgain;
    for( i; i< 300; 1+=>i){
        sgain*.9 =>sgain;
        sgain => s.gain;
        10::ms=>now;
        <<<sgain>>>;
    }
}

fun void fadeNice()
{
    while(true)
    {
        (eT - eCur) * .05 + eCur => eCur;
        eCur => e.gain;
        //(e2T - e2Cur) * .05 + e2Cur => e2Cur;
        //e2Cur => e2.gain;
        5::ms => now;
    }
    
}

