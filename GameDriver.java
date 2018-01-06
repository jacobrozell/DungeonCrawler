import java.util.Scanner;
import java.util.Random;


/** Creates GameDriver class. 
 * Works with Player and Enemy class.
 */
public class GameDriver {
   
   
   /** Main method used as engine.
    * @param args - not used.
    */
   public static void main(String[] args) {
   
     // Setup:
      boolean gameRunning = true;
      int num = 0;
      int layer = 1;
   
      // Introduce name of game:
      System.out.println("\n----------Welcome to Dungeon Divers!----------\n");
      
      // Give short summary of how to play:
      System.out.println("In Dungeon Divers, you progress through layers of dungeons "
         + "\nto level up and see how far you can go!\n");
      System.out.println("Kill 5 enemies in a row to progress to the next layer."
         + "\nThe 5th enemy will be a special boss enemy who is tougher to kill.");
      System.out.println("\nGet through layer 5 and defeat the Imperial Red Dragon to win.\n");
      
      
      // Ask for name of player:
      Scanner sc = new Scanner(System.in);
      System.out.println("Before you begin your crawl through layer 1, what is your name?");
      String tempName = "";
      tempName = sc.nextLine().trim();
            /*Could add a confirmation for name.*/
      
      // Create Player with param name:
      Player player = new Player(tempName);
      
      
      // Main Game Loop begins:
      while (gameRunning) {
      
         //Creates enemy: 
         Enemy e1 = new Enemy();
      
         // Determines what # enemy:
         num += 1;
         if (num > 5) {
            num = 1;
            
            //Post Game enemy stats increased.
            if (layer > 5) {
               e1.levelUp();
               e1.setLuck(1);
            }
            
            //Normal Game enemy stats increased.
            else {
               e1.levelUp();
            }
         }
         
         // Check for Boss / Generate stats for boss:
         if (num == 5) {
            
            //End Boss set stats.
            if (layer == 5) {
               e1.setName("Imperial Red Dragon");
               e1.setAttack(100);
               e1.setHp(150);
               e1.setDefense(0);
               e1.setLuck(e1.getLuck());
            }
            else {
               
               // Normal Bosses:
               String[] eBossList = new String[15];
               eBossList[0] = "Blue Dragon Boss";
               eBossList[1] = "Giant Troll Boss";
               eBossList[2] = "Warlord Shaman Boss";
               eBossList[3] = "Treasure Seeker Goblin Boss";
               eBossList[4] = "Bloodthirsty Gnoll Boss";
               int eBossLength = 4;
            
               Random rn = new Random();
            
               String tName = eBossList[rn.nextInt(eBossLength + 1)];
               
               //Post Game bosses stats increased:
               if (layer > 5) {
                  e1.setName(tName);
                  e1.setAttack(e1.getAttack() + 20);
                  e1.setHp(e1.getHp() + 30);
                  e1.setDefense(e1.getDefense());
                  e1.setLuck(e1.getLuck());
               }
               
               //Normal game bosses stats:
               else {
                  e1.setName(tName);
                  e1.setAttack(e1.getAttack() + 10);
                  e1.setHp(e1.getHp() + 15);
                  e1.setDefense(e1.getDefense() - 5);
                  e1.setLuck(e1.getLuck() - 1);
               }
            }
         }
         
         // Enemy appears / Combat begins:
         System.out.println("\n*Layer " + layer + ": Enemy " + num + " of 5*");
         System.out.println("A " + e1.getName() + " appears!");
         boolean combat = true;
      
      // Combat Loop: 
         while (combat) {
            System.out.println("");
            System.out.println(player.toString());
            System.out.println(e1.toString() + "\n");
            System.out.println("What do you want to do?");
            System.out.println("---[A]ttack, [D]odge, [H]eal---");
            String line = sc.next().toUpperCase();
            char action = line.charAt(0);
            System.out.println("");
         
         // Simplify varaibles:
            String eName = e1.getName();
            int pAtk = player.getAttack();
         
         // Switch for options available (Attack, Dodge, Heal):
            switch(action) {
            
            // Try to attack:
               case 'A':
               
                  //Player hits:
                  if (player.checkHit(player.getLuck())) {
                     e1.takeHit(pAtk - e1.getDefense());
                     int hit = pAtk - e1.getDefense();
                     System.out.println(eName + " took " + hit + " damage!");
                     if (e1.getHp() <= 0) {
                        break;
                     }
                  }
                  
                  //Player misses:
                  else {
                     System.out.println("You missed!");
                  }
                  
                  //Enemy hits:
                  if (e1.checkHit(e1.getLuck())) {
                     int hit = e1.getAttack() - player.getDefense();
                     System.out.println(eName + " hit you for " + hit + "!");
                     player.takeHit(e1.getAttack() - player.getDefense());
                  }
                  
                  //Enemy misses:
                  else {
                     System.out.println(eName + " missed!");
                  }
                  break;
            
            // Try to dodge:
               case 'D':
                  System.out.println("You attempt to block the incoming attack!");
               
                  //Dodge failed:
                  if (e1.checkHit(e1.getLuck() + 3)) {
                     int hit = e1.getAttack() - player.getDefense();
                     System.out.println(eName + " still hit for " + hit + "!");
                     player.takeHit(e1.getAttack() - player.getDefense());
                  }
                  
                  //Dodge is successfull:
                  else {
                     System.out.println("You successfully dodged the incoming attack!");
                     System.out.println("You regained a small portion of your health!");
                     player.regainHealth(5 * player.getLevel());
                  }
                  break;
            
            // Restore Health:
               case 'H':
               
                  //If max health:
                  if (player.getHp() >= player.getMaxHp()) {
                     System.out.println("You are already at full health!");
                     break;
                  }
                  
                  //Regain health (10hp * current player level):
                  else {
                     System.out.println("You use a potion to regain health!");
                     player.restoreHp(10 * player.getLevel());
                     System.out.println("Your health is now " + player.getHp() + ".");
                  }
                  
                  //Check to see if enemy hits: 
                  if (e1.checkHit(e1.getLuck() + 1)) {
                     int hit = e1.getAttack() - player.getDefense();
                     System.out.println(eName + " still hit for " + hit + "!");
                     player.takeHit(e1.getAttack() - player.getDefense());
                  }
                  break;
               
               // Invalid command:
               default:
                  System.out.println("Invalid command.");
                  break;
            }
         
         // Check to see if anyone died:
            if (e1.getHp() <= 0) {
               System.out.println(e1.died());
               combat = false;
               
               //Layer increases if boss defeated:
               if (num == 5) {
                  layer++;
                  
                  //End tutorial / explain level up:
                  if (layer == 2) {
                     System.out.println("Enemies get tougher for every layer, but so do you.");
                     System.out.println("Keep the hordes at bay! Treasure awaits!");
                     System.out.println("When you level up, the stat of your choosing goes up by 10 (20 for HP)."
                        + "\nBut don't worry, the others still go up by 5 (10 for HP).");
                  }
                  
                  //End game / Player defeated final boss:
                  if (layer == 5) {
                     System.out.println("\nYou defeated the Imperial Red Dragon!");
                     System.out.println("Congratulations!");
                     System.out.println("***You have successfully completed Dungeon Divers!***\n" 
                        + "\nYou can keep going however, enemies will get a lot tougher from now on.");
                  }
                  
                  // Level up:
                  System.out.println("\nYou leveled up!");
                  System.out.println("What do you want to upgrade?");
                  System.out.println("---[A]ttack, [D]efense, [H]ealth---");
                  String line2 = sc.next().toUpperCase();
                  char upgrade = line2.charAt(0);
                  boolean levelPhase = true;
                  
                  //Level Loop active (for invalid commands):
                  while (levelPhase) {
                  
                     // Switch for options (Attack, Defense, Health):
                     switch (upgrade) {
                     
                        case 'A':
                           System.out.println("You upgraded attack!");
                           player.levelUp(1);
                           levelPhase = false;
                           break;
                        
                        case 'D':
                           System.out.println("You upgraded defense!");
                           player.levelUp(2);
                           levelPhase = false;
                           break;
                        
                        case 'H':
                           System.out.println("You upgraded health!");
                           player.levelUp(3);
                           levelPhase = false;
                           break;
                        
                        default:
                           System.out.println("Invalid command.");
                           break; 
                     }
                  }
                  System.out.println("--------------------------------------------------------");
               }
            }
            
            //If player dies:
            if (player.getHp() <= 0) {
               combat = false;
               System.out.println(player.died());
               System.exit(0);
            }
         }
      }
   }
}