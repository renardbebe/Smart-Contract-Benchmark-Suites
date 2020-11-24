 

pragma solidity ^0.4.21;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
       
    
     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

}

 
 
 

contract BBBSToken is owned, TokenERC20 {
    struct frozenInfo {
       bool frozenAccount;
       bool frozenAccBytime;
        
       uint time_end_frozen;
       uint time_last_query;
       uint256 frozen_total;
        
    }
    
    struct frozenInfo_prv {
       uint256 realsestep;
    }
    
    uint private constant timerate = 1;
    string public declaration = "frozenInfos will reflush by function QueryFrozenCoins and transfer.";
     
    mapping (address => frozenInfo) public frozenInfos;
    mapping (address => frozenInfo_prv) private frozenInfos_prv;
    
     
    event FrozenFunds(address target, bool frozen);

     
    event FrozenTotal(address indexed from, uint256 value);
     
    function BBBSToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    
    function _resetFrozenInfo(address target) internal {
       frozenInfos[target].frozen_total = 0;
       frozenInfos[target].time_end_frozen = 0;
       frozenInfos_prv[target].realsestep = 0;
       frozenInfos[target].time_last_query = 0;
       frozenInfos[target].frozenAccBytime = false; 
    }
    
    function _refulshFrozenInfo(address target) internal {
       if(frozenInfos[target].frozenAccBytime) 
        {
            uint nowtime = now ; 
            frozenInfos[target].time_last_query = nowtime;
            if(nowtime>=frozenInfos[target].time_end_frozen)
            {
               _resetFrozenInfo(target);              
            }
            else
            {
               uint stepcnt = frozenInfos[target].time_end_frozen - nowtime;
               uint256 releasecoin = stepcnt * frozenInfos_prv[target].realsestep;
               if(frozenInfos[target].frozen_total<=releasecoin)
                  _resetFrozenInfo(target);
               else
               {
                  frozenInfos[target].frozen_total=releasecoin;
               }
            }
        }       
    }
    
     
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
         
         
        require(!frozenInfos[_from].frozenAccount);                      
        require(!frozenInfos[_to].frozenAccount);                        
        require(!frozenInfos[_to].frozenAccBytime); 
                
        if(frozenInfos[_from].frozenAccBytime) 
        {
            _refulshFrozenInfo(_from);
            if(frozenInfos[_from].frozenAccBytime)
            {
               if((balanceOf[_from]-_value)<=frozenInfos[_from].frozen_total)
                   require(false);
            }
        }
        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
         
        frozenInfos[target].frozenAccount = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function freezeAccountByTime(address target, uint time) onlyOwner public {
         
        require (target != 0x0);
        require (balanceOf[target] >= 1); 
        require(!frozenInfos[target].frozenAccBytime);
        require (time >0);
        frozenInfos[target].frozenAccBytime = true;
        uint nowtime = now;
        frozenInfos[target].time_end_frozen = nowtime + time * timerate;
        frozenInfos[target].time_last_query = nowtime;
        frozenInfos[target].frozen_total = balanceOf[target];
        frozenInfos_prv[target].realsestep = frozenInfos[target].frozen_total / (time * timerate);  
        require (frozenInfos_prv[target].realsestep>0);      
        emit FrozenTotal(target, frozenInfos[target].frozen_total);
    }    
    
    function UnfreezeAccountByTime(address target) onlyOwner public {
        _resetFrozenInfo(target);
        emit FrozenTotal(target, frozenInfos[target].frozen_total);
    }
    
    function QueryFrozenCoins(address _from) public returns (uint256 total) {
        require (_from != 0x0);
        require(frozenInfos[_from].frozenAccBytime);
        _refulshFrozenInfo(_from);        
        emit FrozenTotal(_from, frozenInfos[_from].frozen_total);
        return frozenInfos[_from].frozen_total;
    }

}