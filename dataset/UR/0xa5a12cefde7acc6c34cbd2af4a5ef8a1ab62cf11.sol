 

pragma solidity ^0.4.25;

 

 

contract owned {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
}

 

contract game is owned{

 
    
    bool public stop = false;
    
    address public tokenAddress_GIC = 0x340e85491c5f581360811d0ce5cc7476c72900ba;
    address public tokenAddress_Arina = 0x5c0a1EF3C2426064050417aedbD34a3A011fe8e9;
    
    address public address_A = 0xcC22f3Bd8c684463c0Ed6659a001AA62e0a7A146;
    address public address_B = 0xb0D63Fcfb2101C8a1B9b2f0Ff96A13CfEA1A2E65;

    mapping (address => uint) readyTime;
    uint public airdrop_GIC = 25*10**18 ;   
    uint public airdrop_Arina = 500*10**18 ;   
    
    uint public total_airdrop_GIC = 21000000*10**18;  
    uint public total_airdrop_Arina = 84000000*10**18;  
    
    uint public sent_times = 0;  
    uint public sent_limit = total_airdrop_GIC/airdrop_GIC;  

    uint public cooldown = 600;   
    uint24 public Probability = 1000000;   
    
    uint random_source = uint(keccak256(msg.sender, block.difficulty, now));
    
    event Play_game(address indexed from, uint8 player, uint8 comp, uint8 record);
     
    event Random(address indexed from, uint24 random_player, uint24 random_lottery);
     
    

 
    

    function stop_game()onlyOwner public{
        stop = true ;
    }
    
    function start_game()onlyOwner public{
        stop = false ;
    }

    function set_address_GIC(address new_address)onlyOwner public{
        tokenAddress_GIC = new_address;
    }
    
    function set_address_Arina(address new_address)onlyOwner public{
        tokenAddress_Arina = new_address;
    }
    
    function set_address_A(address new_address)onlyOwner public{
        address_A = new_address;
    }
    
    function set_address_B(address new_address)onlyOwner public{
        address_B = new_address;
    }

    function set_cooldown(uint new_cooldown)onlyOwner public{
        cooldown = new_cooldown;
    }

    function withdraw_GIC(uint _amount)onlyOwner public{
        require(ERC20Basic(tokenAddress_GIC).transfer(owner, _amount*10**18));
    }
    
    function withdraw_Arina(uint _amount)onlyOwner public{
        require(ERC20Basic(tokenAddress_Arina).transfer(owner, _amount*10**18));
    }
    
    function withdraw_eth()onlyOwner public{
        owner.transfer(address(this).balance);
    }

 
    function () payable public{
        if (msg.value == 0){
        play_game(0);
        }
    }

    function play_paper()public{
        play_game(0);
    }

    function play_scissors()public{
        play_game(1);
    }

    function play_stone()public{
        play_game(2);
    }

    function play_game(uint8 player) internal{
        require(stop == false);
        
        require(readyTime[msg.sender] < block.timestamp);
        require(player <= 2);
        
        require(sent_times <= sent_limit);
         
        
        random_source += 1;

        uint8 comp=uint8(uint(keccak256(random_source, block.difficulty, block.timestamp))%3);
        uint8 result = compare(player, comp);
        

        if (result == 2){  
            sent_times +=1 ;
            require(ERC20Basic(tokenAddress_GIC).transfer(msg.sender, airdrop_GIC));
            
            (uint _player_amount,uint addressA_amount, uint addressB_amount)
             = Arina_amount();
             
            require(ERC20Basic(tokenAddress_Arina).transfer(msg.sender, _player_amount));
            require(ERC20Basic(tokenAddress_Arina).transfer(address_A , addressA_amount));
            require(ERC20Basic(tokenAddress_Arina).transfer(address_B, addressB_amount));
        }
        
        else if(result == 1){  
        }
        
        else if(result == 0){  
            readyTime[msg.sender] = block.timestamp + cooldown;
        }
        
        else revert();
        
        uint bal = ERC20Basic(tokenAddress_GIC).balanceOf(this) + ERC20Basic(tokenAddress_Arina).balanceOf(this);
        
        uint24 random_player = uint24(keccak256(msg.sender, now, random_source))%Probability;
        uint24 random_lottery = uint24(keccak256(random_source, block.difficulty, bal))%Probability;
        
        emit Play_game(msg.sender, player, comp, result);
        emit Random(msg.sender, random_player, random_lottery);
        
         
        
        if (random_player == random_lottery){
            uint8 _level = level_judgment(msg.sender);
            uint _eth = eth_amount_judgment(_level);
            if (address(this).balance >= _eth){
                msg.sender.transfer(_eth);
            }
            else{
                msg.sender.transfer(address(this).balance);
            }
            
             
        }
        
    }

 

    function compare(uint8 _player,uint _comp) pure internal returns(uint8 result){
         
         
        uint8 _result;

        if (_player==0 && _comp==2){   
            _result = 2;
        }

        else if(_player==2 && _comp==0){  
            _result = 0;
        }

        else if(_player == _comp){  
            _result = 1;
        }

        else{
            if (_player > _comp){  
                _result = 2;
            }
            else{  
                _result = 0;
            }
        }
        return _result;
    }


    function Arina_judgment() view public returns(uint _amount){
        uint Arina_totBalance = ERC20Basic(tokenAddress_Arina).balanceOf(this);
        if (Arina_totBalance >= total_airdrop_Arina/2){
            return airdrop_Arina;
        }
        else if(total_airdrop_Arina/2 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/4){
            return airdrop_Arina/2;
        }
        else if(total_airdrop_Arina/4 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/8){
            return airdrop_Arina/4;
        }
        else if(total_airdrop_Arina/8 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/16){
            return airdrop_Arina/8;
        }
        else if(total_airdrop_Arina/16 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/32){
            return airdrop_Arina/16;
        }
        else if(total_airdrop_Arina/32 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/64){
            return airdrop_Arina/32;
        }
        else if(total_airdrop_Arina/64 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/128){
            return airdrop_Arina/64;
        }
        else if(total_airdrop_Arina/128 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/256){
            return airdrop_Arina/128;
        }
        else if(total_airdrop_Arina/256 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/512){
            return airdrop_Arina/256;
        }
        else if(total_airdrop_Arina/512 > Arina_totBalance
        && Arina_totBalance >= total_airdrop_Arina/1024){
            return airdrop_Arina/512;
        }
        else revert();
    }
    
    function level_judgment(address _address) view public returns(uint8 _level){
        uint GIC_balance = ERC20Basic(tokenAddress_GIC).balanceOf(_address);
        if (GIC_balance <= 1000*10**18){
            return 1;
        }
        else if(1000*10**18 < GIC_balance && GIC_balance <=10000*10**18){
            return 2;
        }
        else if(10000*10**18 < GIC_balance && GIC_balance <=100000*10**18){
            return 3;
        }
        else if(100000*10**18 < GIC_balance && GIC_balance <=500000*10**18){
            return 4;
        }
        else if(500000*10**18 < GIC_balance){
            return 5;
        }
        else revert();
    }
    
    function eth_amount_judgment(uint8 _level) pure public returns(uint _eth){
        if (_level == 1){
            return 1 ether;
        }
        else if (_level == 2){
            return 3 ether;
        }
        else if (_level == 3){
            return 5 ether;
        }
        else if (_level == 4){
            return 10 ether;
        }
        else if (_level == 5){
            return 20 ether;
        }
        else revert();
    }
    
    function Arina_amount_judgment(uint8 _level, uint _Arina) 
    pure public returns(uint _player, uint _addressA, uint _addressB){
        if (_level == 1){
            return (_Arina*5/10, _Arina*1/10, _Arina*4/10);
        }
        else if (_level == 2){
            return (_Arina*6/10, _Arina*1/10, _Arina*3/10);
        }
        else if (_level == 3){
            return (_Arina*7/10, _Arina*1/10, _Arina*2/10);
        }
        else if (_level == 4){
            return (_Arina*8/10, _Arina*1/10, _Arina*1/10);
        }
        else if (_level == 5){
            return (_Arina*9/10, _Arina*1/10, 0);
        }
        else revert();
    }
    
    function Arina_amount() view public returns(uint _player, uint _addressA, uint _addressB){
        uint8 _level = level_judgment(msg.sender);
        uint _amount = Arina_judgment();
        return Arina_amount_judgment(_level, _amount);
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
        return view_readyTime(msg.sender);
    }

}