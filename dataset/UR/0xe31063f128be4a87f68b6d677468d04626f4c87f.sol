 

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    constructor() public {
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


contract DBTBase {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 12;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
    event Approved(address indexed from,address spender, uint256 value);
     
    constructor(
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
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approved(msg.sender,_spender,_value);
        return true;
    }


     
    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract DBToken is owned, DBTBase {

     
    mapping (address => bool) public frozenAccount;
     
    mapping (address => uint256) public balancefrozen;
     
    mapping (address => uint256[][]) public frozeTimeValue;
     
    mapping (address => uint256) public balancefrozenTime;


    bool public isPausedTransfer = false;


     
    event FrozenFunds(address target, bool frozen);

    event FronzeValue(address target,uint256 value);

    event FronzeTimeValue(address target,uint256 value);

    event PauseChanged(bool ispause);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) DBTBase(initialSupply, tokenName, tokenSymbol) public {
        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!isPausedTransfer);
        require (_to != 0x0);                                
        require(balanceOf[_from]>=_value);
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
         
        require(balanceOf[_from].sub(_value)>=balancefrozen[_from]);

        require(accountNoneFrozenAvailable(_from) >=_value);

        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

    function pauseTransfer(bool ispause) onlyOwner public {
        isPausedTransfer = ispause;
        emit PauseChanged(ispause);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        uint256 newmint=mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[target] = balanceOf[target].add(newmint);
        totalSupply = totalSupply.add(newmint);
       emit Transfer(0, this, mintedAmount);
       emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function freezeAccountTimeAndValue(address target, uint256[] times, uint256[] values) onlyOwner public {
        require(times.length >=1 );
        require(times.length == values.length);
        require(times.length<=10);
        uint256[2][] memory timevalue=new uint256[2][](10);
        uint256 lockedtotal=0;
        for(uint i=0;i<times.length;i++)
        {
            uint256 value=values[i].mul(10 ** uint256(decimals));
            timevalue[i]=[times[i],value];
            lockedtotal=lockedtotal.add(value);
        }
        frozeTimeValue[target] = timevalue;
        balancefrozenTime[target]=lockedtotal;
        emit FronzeTimeValue(target,lockedtotal);
    }

    function unfreezeAccountTimeAndValue(address target) onlyOwner public {

        uint256[][] memory lockedTimeAndValue=frozeTimeValue[target];
        
        if(lockedTimeAndValue.length>0)
        {
           delete frozeTimeValue[target];
        }
        balancefrozenTime[target]=0;
    }

    function freezeByValue(address target,uint256 value) public onlyOwner {
       balancefrozen[target]=value.mul(10 ** uint256(decimals));
       emit FronzeValue(target,value);
    }

    function increaseFreezeValue(address target,uint256 value)  onlyOwner public {
       balancefrozen[target]= balancefrozen[target].add(value.mul(10 ** uint256(decimals)));
       emit FronzeValue(target,value);
    }

    function decreaseFreezeValue(address target,uint256 value) onlyOwner public {
            uint oldValue = balancefrozen[target];
            uint newvalue=value.mul(10 ** uint256(decimals));
            if (newvalue >= oldValue) {
                balancefrozen[target] = 0;
            } else {
                balancefrozen[target] = oldValue.sub(newvalue);
            }
            
        emit FronzeValue(target,value);      
    }

     function accountNoneFrozenAvailable(address target) public returns (uint256)  {
        
        uint256[][] memory lockedTimeAndValue=frozeTimeValue[target];

        uint256 avail=0;
       
        if(lockedTimeAndValue.length>0)
        {
           uint256 unlockedTotal=0;
           uint256 now1 = block.timestamp;
           uint256 lockedTotal=0;           
           for(uint i=0;i<lockedTimeAndValue.length;i++)
           {
               
               uint256 unlockTime = lockedTimeAndValue[i][0];
               uint256 unlockvalue=lockedTimeAndValue[i][1];
               
               if(now1>=unlockTime && unlockvalue>0)
               {
                  unlockedTotal=unlockedTotal.add(unlockvalue);
               }
               if(unlockvalue>0)
               {
                   lockedTotal=lockedTotal.add(unlockvalue);
               }
           }
            

           if(lockedTotal > unlockedTotal)
           {
               balancefrozenTime[target]=lockedTotal.sub(unlockedTotal);
           }
           else 
           {
               balancefrozenTime[target]=0;
           }
           
           if(balancefrozenTime[target]==0)
           {
              delete frozeTimeValue[target];
           }
           if(balanceOf[target]>balancefrozenTime[target])
           {
               avail=balanceOf[target].sub(balancefrozenTime[target]);
           }
           else
           {
               avail=0;
           }
           
        }
        else
        {
            avail=balanceOf[target];
        }

        return avail ;
    }


}