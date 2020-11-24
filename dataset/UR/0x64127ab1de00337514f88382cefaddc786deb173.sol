 

pragma solidity ^0.4.20;

contract Gladiethers
{
    address public m_Owner;
    address public partner;

    mapping (address => uint) public gladiatorToPower;  
    mapping (address => uint) public gladiatorToCooldown;
    mapping(address => uint) public gladiatorToQueuePosition;
    mapping(address => uint) public gladiatorToPowerBonus;
    mapping(address => bool)  public trustedContracts;
    address public kingGladiator;
    address[] public queue;

    uint founders = 0;

    event fightEvent(address indexed g1,address indexed g2,uint random,uint fightPower,uint g1Power);
    modifier OnlyOwnerAndContracts() {
        require(msg.sender == m_Owner ||  trustedContracts[msg.sender]);
        _;
    }
    function ChangeAddressTrust(address contract_address,bool trust_flag) public OnlyOwnerAndContracts() {
        require(msg.sender != contract_address);
        trustedContracts[contract_address] = trust_flag;
    }
    
    function Gladiethers() public{
        m_Owner = msg.sender;
    }
    
    function setPartner(address contract_partner) public OnlyOwnerAndContracts(){
        partner = contract_partner;
    }

    function joinArena() public payable returns (bool){

        require( msg.value >= 10 finney );

        if(founders < 50 && gladiatorToPowerBonus[msg.sender] == 0){
            gladiatorToPowerBonus[msg.sender] = 5;  
            founders++;
        }else if(founders < 100 && gladiatorToPowerBonus[msg.sender] == 0){
            gladiatorToPowerBonus[msg.sender] = 2;  
            founders++;
        }else if(founders < 200 && gladiatorToPowerBonus[msg.sender] == 0){
            gladiatorToPowerBonus[msg.sender] = 1;  
            founders++;
        }

        if(queue.length > gladiatorToQueuePosition[msg.sender]){

            if(queue[gladiatorToQueuePosition[msg.sender]] == msg.sender){
                gladiatorToPower[msg.sender] += msg.value;
                return false;
            }
            
        }
        
        enter(msg.sender);
        return true;  

    }

    function enter(address gladiator) private{
        gladiatorToCooldown[gladiator] = now + 1 days;
        queue.push(gladiator);
        gladiatorToQueuePosition[gladiator] = queue.length - 1;
        gladiatorToPower[gladiator] += msg.value;
    }


    function remove(address gladiator) private returns(bool){
        
        if(queue.length > gladiatorToQueuePosition[gladiator]){

            if(queue[gladiatorToQueuePosition[gladiator]] == gladiator){  
            
                queue[gladiatorToQueuePosition[gladiator]] = queue[queue.length - 1];
                gladiatorToQueuePosition[queue[queue.length - 1]] = gladiatorToQueuePosition[gladiator];
                gladiatorToCooldown[gladiator] =  9999999999999;  
                delete queue[queue.length - 1];
                queue.length = queue.length - (1);
                return true;
                
            }
           
        }
        return false;
        
        
    }

    function removeOrc(address _gladiator) public OnlyOwnerAndContracts(){
         remove(_gladiator);
    }

    function setCooldown(address gladiator, uint cooldown) internal{
        gladiatorToCooldown[gladiator] = cooldown;
    }

    function getGladiatorPower(address gladiator) public view returns (uint){
        return gladiatorToPower[gladiator];
    }
    
    function getQueueLenght() public view returns (uint){
        return queue.length;
    }

    function fight(address gladiator1,string _result) public OnlyOwnerAndContracts(){

        uint indexgladiator2 = uint(sha3(_result)) % queue.length;  
        uint randomNumber = uint(sha3(_result)) % 1000;
        address gladiator2 = queue[indexgladiator2];
        
        require(gladiatorToPower[gladiator1] >= 10 finney && gladiator1 != gladiator2);

        
        uint g1chance = getChancePowerWithBonus(gladiator1);
        uint g2chance = getChancePowerWithBonus(gladiator2);
        uint fightPower = SafeMath.add(g1chance,g2chance);

        g1chance = (g1chance*1000)/fightPower;

        if(g1chance <= 958){
            g1chance = SafeMath.add(g1chance,40);
        }else{
            g1chance = 998;
        }

        fightEvent( gladiator1, gladiator2,randomNumber,fightPower,getChancePowerWithBonus(gladiator1));
        uint devFee;

        if(randomNumber <= g1chance ){  
            devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator2],4),100);

            gladiatorToPower[gladiator1] =  SafeMath.add( gladiatorToPower[gladiator1], SafeMath.sub(gladiatorToPower[gladiator2],devFee) );
            queue[gladiatorToQueuePosition[gladiator2]] = gladiator1;
            gladiatorToQueuePosition[gladiator1] = gladiatorToQueuePosition[gladiator2];
            gladiatorToPower[gladiator2] = 0;
            gladiatorToCooldown[gladiator1] = now + 1 days;  

            if(gladiatorToPower[gladiator1] > gladiatorToPower[kingGladiator] ){  
                kingGladiator = gladiator1;
            }

        }else{
             
            devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator1],4),100);

            gladiatorToPower[gladiator2] = SafeMath.add( gladiatorToPower[gladiator2],SafeMath.sub(gladiatorToPower[gladiator1],devFee) );
            gladiatorToPower[gladiator1] = 0;

            if(gladiatorToPower[gladiator2] > gladiatorToPower[kingGladiator] ){
                kingGladiator = gladiator2;
            }

        }

        
        gladiatorToPower[kingGladiator] = SafeMath.add( gladiatorToPower[kingGladiator],SafeMath.div(devFee,4) );  
        gladiatorToPower[m_Owner] = SafeMath.add( gladiatorToPower[m_Owner] , SafeMath.sub(devFee,SafeMath.div(devFee,4)) );  

    }

    function getChancePowerWithBonus(address gladiator) public view returns(uint power){
        return SafeMath.add(gladiatorToPower[gladiator],SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator],gladiatorToPowerBonus[gladiator]),100));
    }


    function withdraw(uint amount) public  returns (bool success){
        address withdrawalAccount;
        uint withdrawalAmount;

         
        if (msg.sender == m_Owner || msg.sender == partner ) {
            withdrawalAccount = m_Owner;
            withdrawalAmount = gladiatorToPower[m_Owner];
            uint partnerFee = SafeMath.div(SafeMath.mul(gladiatorToPower[withdrawalAccount],15),100);

             
            gladiatorToPower[withdrawalAccount] = 0;

            if (!m_Owner.send(SafeMath.sub(withdrawalAmount,partnerFee))) revert();  
            if (!partner.send(partnerFee)) revert();  

            return true;
        }else{

            withdrawalAccount = msg.sender;
            withdrawalAmount = amount;

             
            if(gladiatorToCooldown[msg.sender] < now && gladiatorToPower[withdrawalAccount] >= withdrawalAmount){

                gladiatorToPower[withdrawalAccount] = SafeMath.sub(gladiatorToPower[withdrawalAccount],withdrawalAmount);

                 
                if(gladiatorToPower[withdrawalAccount] < 10 finney){
                    remove(msg.sender);
                }

            }else{
                return false;
            }

        }

        if (withdrawalAmount == 0) revert();

         
        if (!msg.sender.send(withdrawalAmount)) revert();


        return true;
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