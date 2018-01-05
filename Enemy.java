import java.util.Random;

public class Enemy {


// Constant Var:
   protected static int MAX_HP = 50;
   protected static int MAX_ATK = 15;
   protected static int MAX_DEF = 5;  

// Instance Varibles:
   protected int hp = 50;
   protected int attack = 15;
   protected int defense = 5;
   protected String name = "";
   protected int level = 1;
   protected int luck = 5;
   
   
   /** Normal Constructor.
    * Used for random name generation.
    */
   public Enemy() {
     
      String[] eNameList = new String[15];
      eNameList[0] = "Goblin";
      eNameList[1] = "Troll";
      eNameList[2] = "Pixie";
      eNameList[3] = "Wolf";
      eNameList[4] = "Gnoll";
      int eNameLength = 4;
      
      Random rn = new Random();
      
      String tName = eNameList[rn.nextInt(eNameLength + 1)];
      
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      name = tName; 
      
   }
   
   public Enemy(String nameIn) {
   
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      name = nameIn;
   }
   
   
   
   /** sets Hp.
    */
   public void setHp(int hpIn) {
      hp = hpIn;
      
   }
   
   
   /** return Hp.
    */
   public int getHp() {
      return hp;
   }
   
   
   /** sets attack.
    */
   public void setAttack(int atkIn) {
      attack = atkIn;
      
   }
   
   
   /** return attack.
    */
   public int getAttack() {
      return attack;
   }
   
   
   /** sets Defense.
    */
   public void setDefense(int defIn) {
      defense = defIn;
   }
   
   
   /** return Defense.
    */
   public int getDefense() {
      return defense;
   }
   
   
   public String getName() {
      return name;
   }
   
   
   public void setName(String nameIn) {
      name = nameIn;
   }
   
   
   /** Takes hit.
    */
   public void takeHit(int hitIn) {
      hp -= hitIn;
      if (hp < 0) {
         hp = 0;
      }
   }

   
   /** Regains Health.
    */
   public void restoreHp(int hpIn) {
      hp += hpIn;
      if (hp > MAX_HP) {
         hp = MAX_HP;
      }
   }
   
   
   public boolean checkHit(int chance) {
      Random rn = new Random();
      
      int hit = rn.nextInt(10);
      
      if (hit > chance) {
         return true;
      }
      
      else {
         return false;
      }
   }
   
   public void levelUp() {
      level++;
      MAX_HP += 10;
      MAX_ATK += 5;
      MAX_DEF += 5;
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      if (level == 5) {
         luck = 4;
      }
   }
   
   public int getLevel() {
      return level;
   }
   
   public void setLuck(int luckIn) {
      luck = luckIn;
   }
   
   public int getLuck() {
      return luck;
   }
   
   
   public String died() {
      String output = "";
      output += "\nThe " + getName() + " was killed!\n"
         + "--------------------------------------------------------";
      return output;
   }     
    
   
   public String toString() {
      String output = "";
         
      output += this.name + " stats:"
         + "  Health: " + hp
         + "  Attack: " + attack
         + "  Defense: " + defense
         + "  Level: " + level;
         
      return output;
   }
}