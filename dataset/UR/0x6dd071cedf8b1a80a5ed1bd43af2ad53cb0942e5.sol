 

 
 
pragma solidity ^0.4.20;

interface ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 


contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    function AccessAdmin() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}


interface IRaceCoin {
    function addTotalEtherPool(uint256 amount) external;
    function addPlayerToList(address player) external;
    function increasePlayersAttribute(address player, uint16[13] param) external;
    function reducePlayersAttribute(address player, uint16[13] param) external;
}

contract RaceCoin is ERC20, AccessAdmin, IRaceCoin {

    using SafeMath for uint256;

    string public constant name  = "Race Coin";
    string public constant symbol = "Coin";
    uint8 public constant decimals = 0;
    uint256 private roughSupply;
    uint256 public totalRaceCoinProduction;
   
     
    uint256 public bonusDivPercent = 20;

     
    uint256 constant refererPercent = 5;

    

    address[] public playerList;
     
    


    uint256 public totalEtherPool;  
    uint256[] private totalRaceCoinProductionSnapshots;  
    uint256[] private allocatedRaceCoinSnapshots;  
    uint256[] private totalRaceCoinSnapshots;  
    uint256 public nextSnapshotTime;



     
    mapping(address => uint256) private ethBalance;
    mapping(address => uint256) private raceCoinBalance;
    mapping(address => uint256) private refererDivsBalance;

    mapping(address => uint256) private productionBaseValue;  
    mapping(address => uint256) private productionMultiplier;  

    mapping(address => uint256) private attackBaseValue;  
    mapping(address => uint256) private attackMultiplier;  
    mapping(address => uint256) private attackPower;  

    mapping(address => uint256) private defendBaseValue;  
    mapping(address => uint256) private defendMultiplier;  
    mapping(address => uint256) private defendPower;  

    mapping(address => uint256) private plunderBaseValue;  
    mapping(address => uint256) private plunderMultiplier;  
    mapping(address => uint256) private plunderPower;  




    mapping(address => mapping(uint256 => uint256)) private raceCoinProductionSnapshots;  
    mapping(address => mapping(uint256 => bool)) private raceCoinProductionZeroedSnapshots;  
    mapping(address => mapping(uint256 => uint256)) private raceCoinSnapshots; 



    mapping(address => uint256) private lastRaceCoinSaveTime;  
    mapping(address => uint256) public lastRaceCoinProductionUpdate;  
    mapping(address => uint256) private lastRaceCoinFundClaim;  
    mapping(address => uint256) private battleCooldown;  


     


     
    mapping(address => mapping(address => uint256)) private allowed;


    event ReferalGain(address referal, address player, uint256 amount);
    event PlayerAttacked(address attacker, address target, bool success, uint256 raceCoinPlunder);


      
    mapping (address => bool) actionContracts;

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }
    
   


    function RaceCoin() public {
        addrAdmin = msg.sender;
    }
    

    function() external payable {

    }


    function beginWork(uint256 firstDivsTime) external onlyAdmin {

        nextSnapshotTime = firstDivsTime;
    }


      
    function adjustDailyDividends(uint256 newBonusPercent) external onlyAdmin whenNotPaused {

        require(newBonusPercent > 0 && newBonusPercent <= 80);
       
        bonusDivPercent = newBonusPercent;

    }

     
    function totalSupply() public view returns(uint256) {
        return roughSupply; 
    }


    function balanceOf(address player) public view returns(uint256) {
        return raceCoinBalance[player] + balanceOfUnclaimedRaceCoin(player);
    }


    function balanceOfUnclaimedRaceCoin(address player) internal view returns (uint256) {
        uint256 lastSave = lastRaceCoinSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (getRaceCoinProduction(player) * (block.timestamp - lastSave)) / 100;
        }
        return 0;
    }


    function getRaceCoinProduction(address player) public view returns (uint256){
        return raceCoinProductionSnapshots[player][lastRaceCoinProductionUpdate[player]];
    }


    function etherBalanceOf(address player) public view returns(uint256) {
        return ethBalance[player];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        updatePlayersRaceCoin(msg.sender);
        require(amount <= raceCoinBalance[msg.sender]);
        
        raceCoinBalance[msg.sender] -= amount;
        raceCoinBalance[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
        updatePlayersRaceCoin(player);
        require(amount <= allowed[player][msg.sender] && amount <= raceCoinBalance[player]);
        
        raceCoinBalance[player] -= amount;
        raceCoinBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;
        
        emit Transfer(player, recipient, amount);
        return true;
    }


    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }

    function allowance(address player, address approvee) public view returns(uint256){
        return allowed[player][approvee];
    }


    function addPlayerToList(address player) external{
        
        require(actionContracts[msg.sender]);
        require(player != address(0));

        bool b = false;

         
        for (uint256 i = 0; i < playerList.length; i++) {
            if(playerList[i] == player){
               b = true;
               break;
            }
        } 

        if(!b){
            playerList.push(player);
        }   
    }


    function getPlayerList() external view returns ( address[] ){
        return playerList;
    }





    function updatePlayersRaceCoin(address player) internal {
        uint256 raceCoinGain = balanceOfUnclaimedRaceCoin(player);
        lastRaceCoinSaveTime[player] = block.timestamp;
        roughSupply += raceCoinGain;
        raceCoinBalance[player] += raceCoinGain;
    }

     
    function increasePlayersAttribute(address player, uint16[13] param) external{


        require(actionContracts[msg.sender]);
        require(player != address(0));


         
        updatePlayersRaceCoin(player);
        uint256 increase;
        uint256 newProduction;
        uint256 previousProduction;

        previousProduction = getRaceCoinProduction(player);

        productionBaseValue[player] = productionBaseValue[player].add(param[3]);
        productionMultiplier[player] = productionMultiplier[player].add(param[7]);

        newProduction = productionBaseValue[player].mul(100 + productionMultiplier[player]).div(100);

        increase = newProduction.sub(previousProduction);

        raceCoinProductionSnapshots[player][allocatedRaceCoinSnapshots.length] = newProduction;
        lastRaceCoinProductionUpdate[player] = allocatedRaceCoinSnapshots.length;
        totalRaceCoinProduction += increase;




         
        attackBaseValue[player] = attackBaseValue[player].add(param[4]);
        attackMultiplier[player] = attackMultiplier[player].add(param[8]);
        attackPower[player] = attackBaseValue[player].mul(100 + attackMultiplier[player]).div(100);


         
        defendBaseValue[player] = defendBaseValue[player].add(param[5]);
        defendMultiplier[player] = defendMultiplier[player].add(param[9]);
        defendPower[player] = defendBaseValue[player].mul(100 + defendMultiplier[player]).div(100);


         
        plunderBaseValue[player] = plunderBaseValue[player].add(param[6]);
        plunderMultiplier[player] = plunderMultiplier[player].add(param[10]);

        plunderPower[player] = plunderBaseValue[player].mul(100 + plunderMultiplier[player]).div(100);


    }


     
    function reducePlayersAttribute(address player, uint16[13] param) external{

        require(actionContracts[msg.sender]);
        require(player != address(0));


         
        updatePlayersRaceCoin(player);


        uint256 decrease;
        uint256 newProduction;
        uint256 previousProduction;


        previousProduction = getRaceCoinProduction(player);

        productionBaseValue[player] = productionBaseValue[player].sub(param[3]);
        productionMultiplier[player] = productionMultiplier[player].sub(param[7]);

        newProduction = productionBaseValue[player].mul(100 + productionMultiplier[player]).div(100);

        decrease = previousProduction.sub(newProduction);
        
        if (newProduction == 0) {  
            raceCoinProductionZeroedSnapshots[player][allocatedRaceCoinSnapshots.length] = true;
            delete raceCoinProductionSnapshots[player][allocatedRaceCoinSnapshots.length];  
        } else {
            raceCoinProductionSnapshots[player][allocatedRaceCoinSnapshots.length] = newProduction;
        }
        
        lastRaceCoinProductionUpdate[player] = allocatedRaceCoinSnapshots.length;
        totalRaceCoinProduction -= decrease;




         
        attackBaseValue[player] = attackBaseValue[player].sub(param[4]);
        attackMultiplier[player] = attackMultiplier[player].sub(param[8]);
        attackPower[player] = attackBaseValue[player].mul(100 + attackMultiplier[player]).div(100);


         
        defendBaseValue[player] = defendBaseValue[player].sub(param[5]);
        defendMultiplier[player] = defendMultiplier[player].sub(param[9]);
        defendPower[player] = defendBaseValue[player].mul(100 + defendMultiplier[player]).div(100);


         
        plunderBaseValue[player] = plunderBaseValue[player].sub(param[6]);
        plunderMultiplier[player] = plunderMultiplier[player].sub(param[10]);
        plunderPower[player] = plunderBaseValue[player].mul(100 + plunderMultiplier[player]).div(100);


    }


    function attackPlayer(address player,address target) external {
        require(battleCooldown[player] < block.timestamp);
        require(target != player);

        updatePlayersRaceCoin(target);
        require(balanceOf(target) > 0);
        
        uint256 attackerAttackPower = attackPower[player];
        uint256 attackerplunderPower = plunderPower[player];
        uint256 defenderDefendPower = defendPower[target];
        

        if (battleCooldown[target] > block.timestamp) {  
            defenderDefendPower = defenderDefendPower.div(2);
        }
        
        if (attackerAttackPower > defenderDefendPower) {
            battleCooldown[player] = block.timestamp + 30 minutes;
            if (balanceOf(target) > attackerplunderPower) {
               
                uint256 unclaimedRaceCoin = balanceOfUnclaimedRaceCoin(target);
                if (attackerplunderPower > unclaimedRaceCoin) {
                    uint256 raceCoinDecrease = attackerplunderPower - unclaimedRaceCoin;
                    raceCoinBalance[target] -= raceCoinDecrease;
                    roughSupply -= raceCoinDecrease;
                } else {
                    uint256 raceCoinGain = unclaimedRaceCoin - attackerplunderPower;
                    raceCoinBalance[target] += raceCoinGain;
                    roughSupply += raceCoinGain;
                }
                raceCoinBalance[player] += attackerplunderPower;
                emit PlayerAttacked(player, target, true, attackerplunderPower);
            } else {
                emit PlayerAttacked(player, target, true, balanceOf(target));
                raceCoinBalance[player] += balanceOf(target);
                raceCoinBalance[target] = 0;
            }
            
            lastRaceCoinSaveTime[target] = block.timestamp;
            lastRaceCoinSaveTime[player] = block.timestamp;
           
        } else {
            battleCooldown[player] = block.timestamp + 10 minutes;
            emit PlayerAttacked(player, target, false, 0);
        }
    }



    function getPlayersBattleStats(address player) external view returns (uint256, uint256, uint256, uint256){

        return (attackPower[player], defendPower[player], plunderPower[player], battleCooldown[player]);
    }

    
    function getPlayersAttributesInt(address player) external view returns (uint256, uint256, uint256, uint256){
        return (getRaceCoinProduction(player), attackPower[player], defendPower[player], plunderPower[player]); 
    }


    function getPlayersAttributesMult(address player) external view returns (uint256, uint256, uint256, uint256){
        return (productionMultiplier[player], attackMultiplier[player], defendMultiplier[player], plunderMultiplier[player]);
    }
    

    function withdrawEther(uint256 amount) external {
        require(amount <= ethBalance[msg.sender]);
        ethBalance[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }


    function getBalance() external view returns(uint256) {
        return totalEtherPool;
    }


    function addTotalEtherPool(uint256 amount) external{
        require(amount > 0);
        totalEtherPool += amount;
    }


     
    function getGameInfo(address player) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256){
       
        return (block.timestamp, totalEtherPool, totalRaceCoinProduction,nextSnapshotTime, balanceOf(player), ethBalance[player], getRaceCoinProduction(player));
    }


   



    function claimRaceCoinDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) external {
        require(startSnapshot <= endSnapShot);
        require(startSnapshot >= lastRaceCoinFundClaim[msg.sender]);
        require(endSnapShot < allocatedRaceCoinSnapshots.length);
        
        uint256 dividendsShare;


        for (uint256 i = startSnapshot; i <= endSnapShot; i++) {

            uint256 raceCoinDuringSnapshot = raceCoinSnapshots[msg.sender][i];

            dividendsShare += (allocatedRaceCoinSnapshots[i] * raceCoinDuringSnapshot) / totalRaceCoinSnapshots[i];
        }

        
        lastRaceCoinFundClaim[msg.sender] = endSnapShot + 1;
        
        uint256 referalDivs;
        if (referer != address(0) && referer != msg.sender) {
            referalDivs = dividendsShare.mul(refererPercent).div(100);  
            ethBalance[referer] += referalDivs;
            refererDivsBalance[referer] += referalDivs;
            emit ReferalGain(referer, msg.sender, referalDivs);
        }
        
        ethBalance[msg.sender] += dividendsShare - referalDivs;
    }

     
    function viewUnclaimedRaceCoinDividends(address player) external view returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastRaceCoinFundClaim[player];
        uint256 latestSnapshot = allocatedRaceCoinSnapshots.length - 1;  
        
        uint256 dividendsShare;
        
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {

            uint256 raceCoinDuringSnapshot = raceCoinSnapshots[player][i];

            dividendsShare += (allocatedRaceCoinSnapshots[i] * raceCoinDuringSnapshot) / totalRaceCoinSnapshots[i];
        }

        return (dividendsShare, startSnapshot, latestSnapshot);
    }


    function getRefererDivsBalance(address player)  external view returns (uint256){
        return refererDivsBalance[player];
    }



     
    function snapshotDailyRaceCoinFunding() external onlyAdmin whenNotPaused {
       
        uint256 todaysRaceCoinFund = (totalEtherPool * bonusDivPercent) / 100;  
        totalEtherPool -= todaysRaceCoinFund;
        
        totalRaceCoinProductionSnapshots.push(totalRaceCoinProduction);
        allocatedRaceCoinSnapshots.push(todaysRaceCoinFund);
        nextSnapshotTime = block.timestamp + 24 hours;

        
        for (uint256 i = 0; i < playerList.length; i++) {
            updatePlayersRaceCoin(playerList[i]);
            raceCoinSnapshots[playerList[i]][lastRaceCoinProductionUpdate[playerList[i]]] = raceCoinBalance[playerList[i]];
        } 
        totalRaceCoinSnapshots.push(roughSupply);
    }

}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}