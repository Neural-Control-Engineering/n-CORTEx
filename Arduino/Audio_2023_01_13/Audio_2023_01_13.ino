

unsigned long int reg;
int Onset = 3; //change to 1 if no onset tone
int Reward= 7;
int NoLick = 6;
int noise = 10;
int Tone1 = 11;
//int Tone2 = 5;
  
void setup() {
 
  
  // Audio
  pinMode(Onset, INPUT);
  pinMode(Reward, INPUT);
  pinMode(NoLick, INPUT); 
  pinMode(noise, OUTPUT);
  pinMode(Tone1, OUTPUT);
  //pinMode(Tone2, OUTPUT);
  digitalWrite(Onset, LOW);
  digitalWrite(Reward, LOW);
  digitalWrite(NoLick, LOW);

  reg = 0x55aa55aaL; //The seed for the bitstream. It can be anything except 0.
}

void loop() {
  
  // Audio
  if (digitalRead(Onset) == 1) {
    tone(Tone1, 2000, 500);
    delay(1);
  }

  else if (digitalRead(NoLick) == 1) {
    tone(Tone1, 1000, 2000);
  }

  else if (digitalRead(Reward) == 1) {
    delay(200);
    tone(Tone1, 3000, 500);
    
  }

  generateNoise();
}

void generateNoise(){
   unsigned long int newr;
   unsigned char lobit;
   unsigned char b31, b29, b25, b24;
   b31 = (reg & (1L << 31)) >> 31;
   b29 = (reg & (1L << 29)) >> 29;
   b25 = (reg & (1L << 25)) >> 25;
   b24 = (reg & (1L << 24)) >> 24;
   lobit = b31 ^ b29 ^ b25 ^ b24;
   newr = (reg << 1) | lobit;
   reg = newr;
   digitalWrite(noise, reg & 1);
   delayMicroseconds (80); // Changing this value changes the frequency.
}
