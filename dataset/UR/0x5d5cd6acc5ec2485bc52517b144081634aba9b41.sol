 

pragma solidity ^0.4.24;

 

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}    

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract game is owned{
    
 
    address public tokenAddress = 0x340e85491c5F581360811d0cE5CC7476c72900Ba;
    
    mapping (address => uint) readyTime;
    uint public amount = 1000*10**18 ;   
    uint public cooldown = 300;   
    mapping (address => uint8) record;

 
    function set_amount(uint new_amount)onlyOwner{
        amount = new_amount*10**18;
    }
    
    function set_address(address new_address)onlyOwner{
        tokenAddress = new_address;
    }
    
    function set_cooldown(uint new_cooldown)onlyOwner{
        cooldown = new_cooldown;
    }
    
    function withdraw(uint _amount)onlyOwner{
        require(ERC20Basic(tokenAddress).transfer(owner, _amount*10**18));
    }
    
 
    function (){
        play_game(0);
    }
    
    function play_paper(){
        play_game(0);
    }
    
    function play_scissors(){
        play_game(1);
    }
    
    function play_stone(){
        play_game(2);
    }
    
    function play_game(uint8 play) internal{
        require(readyTime[msg.sender] < block.timestamp);
        require(play <= 2);
        
        uint8 comp=uint8(uint(keccak256(block.difficulty, block.timestamp))%3);
        uint8 result = compare(play, comp);
        
        record[msg.sender] = result * 9 + play * 3 + comp ;
        
        if (result == 2){  
            require(ERC20Basic(tokenAddress).transfer(msg.sender, amount));
        }
        
        else if(result == 1){  
        }
        
        else if(result == 0)  
            readyTime[msg.sender] = block.timestamp + cooldown;
    }
    
    function compare(uint8 player,uint computer) internal returns(uint8 result){
         
         
        uint8 _result;
        
        if (player==0 && computer==2){   
            _result = 2;
        }
        
        else if(player==2 && computer==0){  
            _result = 0;
        }
        
        else if(player == computer){  
            _result = 1;
        }
        
        else{
            if (player > computer){  
                _result = 2;
            }
            else{  
                _result = 0;
            }
        }
        return _result;
    }
    
 

    function judge(uint8 orig) internal returns(uint8 result, uint8 play, uint8 comp){
        uint8 _result = orig/9;
        uint8 _play = (orig%9)/3;
        uint8 _comp = orig%3;
        return(_result, _play, _comp);
    }
    
    function mora(uint8 orig) internal returns(string _mora){
         
            if (orig == 0){
                return "paper";
            }
            else if (orig == 1){
                return "scissors";
            }
            else if (orig == 2){
                return "stone";
            }
            else {
                return "error";
            }
        }
        
    function win(uint8 _result) internal returns(string result){
         
        if (_result == 0){
                return "lose!!";
            }
            else if (_result == 1){
                return "draw~~";
            }
            else if (_result == 2){
                return "win!!!";
            }
            else {
                return "error";
            }
    }
    
    function resolve(uint8 orig) internal returns(string result, string play, string comp){
        (uint8 _result, uint8 _play, uint8 _comp) = judge(orig);
        return(win(_result), mora(_play), mora(_comp));
    }
    
 

    function view_last_result(address _address) view public returns(string result, string player, string computer){
        return resolve(record[_address]);
    }
        
    function self_last_result() view public returns(string result, string player, string computer){
        view_last_result(msg.sender);
    }
    
    function view_readyTime(address _address) view public returns(uint _readyTime){
        if (block.timestamp >= readyTime[_address]){
        return 0 ;
        }
        else{
        return readyTime[_address] - block.timestamp ;
        }
    }
    
    function self_readyTime() view public returns(uint _readyTime){
        view_readyTime(msg.sender);
    }
    
}