 

pragma solidity ^0.4.20;

contract Gladiethers
{
    address public m_Owner;
    address public partner;

    mapping (address => uint) public gladiatorToPower;  
    mapping (address => uint) public gladiatorToCooldown;
    mapping(address => uint) public gladiatorToQueuePosition;
    mapping(address => bool)  public trustedContracts;
    uint public m_OwnerFees = 0;
    uint public initGameAt = 1529532000;
    address public kingGladiator;
    address public kingGladiatorFounder;
    address public oraclizeContract;
    address[] public queue;
    
    bool started = false;

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
    
    function setOraclize(address contract_oraclize) public OnlyOwnerAndContracts(){
        require(!started);
        oraclizeContract = contract_oraclize;
        started = true;
    }

    function joinArena() public payable returns (bool){

        require( msg.value >= 10 finney && getGladiatorCooldown(msg.sender) != 9999999999999);

        if(queue.length > gladiatorToQueuePosition[msg.sender]){

            if(queue[gladiatorToQueuePosition[msg.sender]] == msg.sender){
                gladiatorToPower[msg.sender] += msg.value;
                checkKingFounder(msg.sender);
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
        checkKingFounder(gladiator);
    }
    
    function checkKingFounder(address gladiator) internal{
        if(gladiatorToPower[gladiator] > gladiatorToPower[kingGladiatorFounder] && now < initGameAt){
            kingGladiatorFounder = gladiator;
        }
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

    function removeOrc(address _gladiator) public {
        require(msg.sender == oraclizeContract);
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
    
    function getGladiatorCooldown(address gladiator) public view returns (uint){
        return gladiatorToCooldown[gladiator];
    }
    

    function fight(address gladiator1,string _result) public {

        require(msg.sender == oraclizeContract);
        
         
        if(queue.length == 0){  
            gladiatorToCooldown[gladiator1] = now + 1 days;
            queue.push(gladiator1);
            gladiatorToQueuePosition[gladiator1] = queue.length - 1;
            kingGladiator = gladiator1;
        }else{
        
            uint indexgladiator2 = uint(sha3(_result)) % queue.length;  
            uint randomNumber = uint(sha3(_result)) % 1000;
            address gladiator2 = queue[indexgladiator2];
            
            require(gladiatorToPower[gladiator1] >= 10 finney && gladiator1 != gladiator2);
    
            
            uint g1chance = gladiatorToPower[gladiator1];
            uint g2chance =  gladiatorToPower[gladiator2];
            uint fightPower = SafeMath.add(g1chance,g2chance);
    
            g1chance = (g1chance*1000)/fightPower;
    
            if(g1chance <= 958){
                g1chance = SafeMath.add(g1chance,40);
            }else{
                g1chance = 998;
            }
    
            fightEvent( gladiator1, gladiator2,randomNumber,fightPower,gladiatorToPower[gladiator1]);
            uint devFee;
    
            if(randomNumber <= g1chance ){  
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator2],5),100);
    
                gladiatorToPower[gladiator1] =  SafeMath.add( gladiatorToPower[gladiator1], SafeMath.sub(gladiatorToPower[gladiator2],devFee) );
                queue[gladiatorToQueuePosition[gladiator2]] = gladiator1;
                gladiatorToQueuePosition[gladiator1] = gladiatorToQueuePosition[gladiator2];
                gladiatorToPower[gladiator2] = 0;
                gladiatorToCooldown[gladiator1] = now + 1 days;  
    
                if(gladiatorToPower[gladiator1] > gladiatorToPower[kingGladiator] ){  
                    kingGladiator = gladiator1;
                }
    
            }else{
                 
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator1],5),100);
    
                gladiatorToPower[gladiator2] = SafeMath.add( gladiatorToPower[gladiator2],SafeMath.sub(gladiatorToPower[gladiator1],devFee) );
                gladiatorToPower[gladiator1] = 0;
                gladiatorToCooldown[gladiator1] = 0;
                
                if(gladiatorToPower[gladiator2] > gladiatorToPower[kingGladiator] ){
                    kingGladiator = gladiator2;
                }

        }

        
        kingGladiator.transfer(SafeMath.div(devFee,5));  
        m_OwnerFees = SafeMath.add( m_OwnerFees , SafeMath.sub(devFee,SafeMath.div(devFee,5)) );  
        }
        
        

    }


    function withdraw(uint amount) public  returns (bool success){
        address withdrawalAccount;
        uint withdrawalAmount;

         
        if (msg.sender == m_Owner || msg.sender == partner ) {
            withdrawalAccount = m_Owner;
            withdrawalAmount = m_OwnerFees;
            uint kingGladiatorFounderProffits = SafeMath.div(withdrawalAmount,4);
            uint partnerFee =  SafeMath.div(SafeMath.mul(SafeMath.sub(withdrawalAmount,kingGladiatorFounderProffits),15),100);

             
            m_OwnerFees = 0;

            if (!m_Owner.send(SafeMath.sub(SafeMath.sub(withdrawalAmount,partnerFee),kingGladiatorFounderProffits))) revert();  
            if (!partner.send(partnerFee)) revert();  
            if (!kingGladiatorFounder.send(kingGladiatorFounderProffits)) revert();  

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