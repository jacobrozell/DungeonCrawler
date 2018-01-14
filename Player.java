import java.util.Random;


/** Creates player class and methods.
 */
public class Player {


    // Constant Var:
    private static int MAX_HP = 60;
    private static int MAX_ATK = 25;
    private static int MAX_DEF = 10;
    private static int level = 1;


    // Instance Varibles:
    private int hp = 60;
    private int attack = 25;
    private int defense = 10;
    private int luck = 3;
    private int goldCount = 0;

    private String name = "";


    /** Normal Constructor.
     * @param nameIn - name
     */
    public Player(String nameIn) {
        hp = MAX_HP;
        attack = MAX_ATK;
        defense = MAX_DEF;
        name = nameIn;
    }


    /** Override normal constructor for testing.
     * Adds 'level' param.
     * @param hpIn - hp
     * @param attackIn - attack
     * @param defenseIn - defense
     * @param levelIn - level
     */
    public Player(int hpIn, int attackIn, int defenseIn, int levelIn) {
        hp = hpIn;
        attack = attackIn;
        defense = defenseIn;
        level = levelIn;
    }


    /** Sets Hp.
     * @param hpIn - hp
     */
    public void setHp(int hpIn) {
        hp = hpIn;

        if (hp > MAX_HP) {
            hp = MAX_HP;
        }
    }


    /** Return Hp.
     * @return hp
     */
    public int getHp() {
        return hp;
    }


    /** Return max_hp.
     * @return MAX_HP
     */
    public int getMaxHp() {
        return MAX_HP;
    }


    /** Sets attack.
     * @param atkIn - attack
     */
    public void setAttack(int atkIn) {
        attack = atkIn;

        if (attack > MAX_ATK) {
            attack = MAX_ATK;
        }
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

        if (defense > MAX_DEF) {
            defense = MAX_DEF;
        }
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


    /** Takes hit (Hp - hitIn).
     * @param hitIn - hit
     */
    public void takeHit(int hitIn) {
        hp -= hitIn;
        if (hp < 0) {
            hp = 0;
        }
    }


    /** Levels up.
     * @param in - int 0, 1, 2
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

        //Player chose def:
        if (in == 2) {
            MAX_DEF += 10;
        }
        else {
            MAX_DEF += 5;
        }

        //Player chose Hp:
        if (in == 3) {
            MAX_HP += 20;
        }
        else {
            MAX_HP += 10;
        }

        hp = MAX_HP;
        attack = MAX_ATK;
        defense = MAX_DEF;
    }


    /** Return current level.
     * @return level
     */
    public int getLevel() {
        return level;
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


    /** Checks to see if player hits (RNG).
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


    /** Sets luck.
     * @param luckIn - luck
     */
    public void setLuck(int luckIn) {
        luck = luckIn;
    }


    /** Return luck.
     * @return luck
     */
    public int getLuck() {
        return luck;
    }


    /** Adds gold.
     * @param goldIn - gold
     */
    public void addGold(int goldIn) {
        goldCount += goldIn;
    }



    /** Returns goldCount.
     *
     * @return goldCount
     */
    public int getGold() {
        return goldCount;
    }





    /** Return died.
     * @return output
     */
    public String died() {
        String output = "";
        output += "\nYou died!";
        output += "\n--------------------------------------------------------";
        return output;
    }


    /** Return player stats.
     * @return output
     */
    public String toString() {
        String output = "";

        output += name + " stats:"
                + "  Health: " + hp
                + "  Attack: " + attack
                + "  Defense: " + defense
                + "  Level: " + level
                + "  Gold: " + goldCount;

        return output;
    }

}