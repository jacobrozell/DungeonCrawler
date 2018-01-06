import java.util.Random;

/** Creates enemy class and methods.
 *
 */
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
   
   /** Used for bosses. 
    * @param nameIn - name
    */
   public Enemy(String nameIn) {
   
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      name = nameIn;
   }
   
   
   
   /** Sets Hp.
    * @param hpIn - hp
    */
   public void setHp(int hpIn) {
      hp = hpIn;
      
   }
   
   
   /** Return Hp.
    * @return hp
    */
   public int getHp() {
      return hp;
   }
   
   
   /** Sets attack.
    * @param atkIn - atk
    */
   public void setAttack(int atkIn) {
      attack = atkIn;
   }
   
   
   /** Return attack.
    * @return attack
    */
   public int getAttack() {
      return attack;
   }
   
   
   /** Sets Defense.
    * @param defIn - defense
    */
   public void setDefense(int defIn) {
      defense = defIn;
   }
   
   
   /** Return Defense.
    * @return defense
    */
   public int getDefense() {
      return defense;
   }
   
   
   /** Return name.
    * @return name
    */
   public String getName() {
      return name;
   }
   
   
   /** Sets name.
    * @param nameIn - name
    */
   public void setName(String nameIn) {
      name = nameIn;
   }
   
   
   /** Takes hit (Hp - hitIn).
    * @param hitIn - hit
    *
    */
   public void takeHit(int hitIn) {
      hp -= hitIn;
      if (hp < 0) {
         hp = 0;
      }
   }

   
   /** Regains Health.
    * @param hpIn - hp
    */
   public void restoreHp(int hpIn) {
      hp += hpIn;
      if (hp > MAX_HP) {
         hp = MAX_HP;
      }
   }
   
   
   /** Checks to see if enemy hits (RNG).
    * @param chance = 'dice' roll (0,9)
    * @return true/false
    */
   public boolean checkHit(int chance) {
      Random rn = new Random();
      
      int hit = rn.nextInt(10);
      
      if (hit >= chance) {
         return true;
      }
      
      else {
         return false;
      }
   }
   
   
   /** Levels up.
    */
   public void levelUp() {
      level++;
      MAX_HP += 15;
      MAX_ATK += 15;
      MAX_DEF += 5;
      hp = MAX_HP;
      attack = MAX_ATK;
      defense = MAX_DEF;
      if (level == 4) {
         luck = 3;
      }
   }
   
   
   /** Return current level.
    * @return level
    */
   public int getLevel() {
      return level;
   }
   
   
   /** Sets luck.
    * @param luckIn - luck
    */
   public void setLuck(int luckIn) {
      luck = luckIn;
   }
   
   
   /** Return Luck.
    * @return luck
    */
   public int getLuck() {
      return luck;
   }
   
   
   /** Return died.
    * @return output
    */
   public String died() {
      String output = "";
      output += "\nThe " + getName() + " was killed!\n"
         + "--------------------------------------------------------";
      return output;
   }     
    
    
   /** Return enemy stats.
    * @return output
    */
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