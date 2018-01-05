import java.util.Random;

public class Player {


// Constant Var:
   protected static int MAX_HP = 60;
   protected static int MAX_ATK = 25;
   protected static int MAX_DEF = 10;  
   protected static int level = 1;

// Instance Varibles:
   protected int hp = 60;
   protected int attack = 25;
   protected int defense = 10;
   protected int luck = 3;
   
   protected String name = "";

   /** Normal Constructor.
    */
   public Player(String nameIn) {
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      name = nameIn;
   }
   
   
   /** Constructor for enemy inheritance.
    */
   public Player() {
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
   }
   
   /** Override normal constructor for testing.
    * Adds 'level' param.
    */
   public Player(int hpIn, int attackIn, int defenseIn, int levelIn) {
      hp = hpIn;
      attack = attackIn;
      defense = defenseIn;
      level = levelIn;
   }
   
   
   /** sets Hp.
    */
   public void setHp(int hpIn) {
      hp = hpIn;
      
      if (hp > MAX_HP) {
         hp = MAX_HP;
      }
   }
   
   
   /** return Hp.
    */
   public int getHp() {
      return hp;
   }
   
   public int getMaxHp() {
      return MAX_HP;
   }
   
   
   /** sets attack.
    */
   public void setAttack(int atkIn) {
      attack = atkIn;
      
      if (attack > MAX_ATK) {
         attack = MAX_ATK;
      }
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
      
      if (defense > MAX_DEF) {
         defense = MAX_DEF;
      }
   }
   
   
   /** return Defense.
    */
   public int getDefense() {
      return defense;
   }
   
   
   public String getName() {
      return name;
   }
   
   
   /** Takes hit.
    */
   public void takeHit(int hitIn) {
      hp -= hitIn;
      if (hp < 0) {
         hp = 0;
      }
   }
   
   
   /** Levels up.
    */
   public void levelUp(int in) {
   
      level += 1;
      
      //Player chose atk:
      if (in == 1) {
         MAX_ATK += 10;
      }
      else {
         MAX_ATK += 5;
      }
      
      //Player chose def
      if (in == 2) {
         MAX_DEF += 10;
      }
      else {
         MAX_DEF += 5;
      }
      
      //Player chose Hp:
      if (in == 3) {
         MAX_HP += 10;
      }
      else {
         MAX_HP += 5;
      }

      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
   }
   
   
   public int getLevel() {
      return level;
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
   
   
   public void setLuck(int luckIn) {
      luck = luckIn;
   }
   
   
   public int getLuck() {
      return luck;
   }
   
   
   public String died() {
      String output = "";
      output += "You died!";
      output += "\n--------------------------------------------------------";  
      return output;
   } 
   
   
   
   public String toString() {
      String output = "";
         
      output += name + " stats:"
         + "  Health: " + hp
         + "  Attack: " + attack
         + "  Defense: " + defense
         + "  Level: " + level;
         
      return output;
   }
   
}