 

pragma solidity ^0.4.26;
    
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
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
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Basic {
    uint public decimals;
    string public    name;
    string public   symbol;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    
    address[] users;
    
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
 


contract GNBToken is ERC20{
    using SafeMath for uint;
    

    address public platformAdmin;
    
    
    mapping(address=>uint256) public tokenRateArray;
    mapping(address=>uint256) public tokenRateSignArray;
    mapping(address=>bool) public tokenExchangeLock;
    
    uint256 public startTime=1575216000;
    uint256 public endTime=1581696000;
    
    mapping (address => bool) public frozenAccount; 
    mapping (address => uint256) public frozenTimestamp; 
    
    
    

    
    modifier onlyOwner() {
        require(msg.sender == platformAdmin);
        _;
    }

    constructor(string _tokenName, string _tokenSymbol,uint256 _decimals,uint _initialSupply) public {
        platformAdmin = msg.sender;
        _totalSupply = _initialSupply * 10 ** uint256(_decimals); 
        decimals=_decimals;
        name = _tokenName;
        symbol = _tokenSymbol;
        balances[msg.sender]=_totalSupply;
    }
    

    function  setTokenArrRate(address[] _tokenArrs,uint256[] rates,uint256[] signs) public  onlyOwner returns (bool) {
        for(uint i=0;i<_tokenArrs.length;i++){
            tokenRateArray[_tokenArrs[i]]=rates[i];
            tokenRateSignArray[_tokenArrs[i]]=signs[i];
        }
         return true;
    }
    
    
    function  setTokenRate(address _tokenAddress,uint256 rate,uint256 sign) public  onlyOwner returns (bool) {
         require(rate>=1);
         tokenRateSignArray[_tokenAddress]=sign;
         tokenRateArray[_tokenAddress]=rate;
         return true;
    }
    
    
    function  setTokenExchangeLock(address _tokenAddress,bool _flag) public  onlyOwner returns (bool) {
         tokenExchangeLock[_tokenAddress]=_flag;
         return true;
    }

    
     function totalSupply() public constant returns (uint){
         return _totalSupply;
     }
     
      function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
          }
  
        function approve(address _spender, uint _value) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
        }
        
        function approveErc(address _tokenAddress,address _spender, uint _value) onlyOwner{
            ERC20 token =ERC20(_tokenAddress);
            token.approve(_spender,_value);
        }
 
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        
        
       function transfer(address _to, uint _value) public {
            require(balances[msg.sender] >= _value);
            require(balances[_to].add(_value) > balances[_to]);
            balances[msg.sender]=balances[msg.sender].sub(_value);
            balances[_to]=balances[_to].add(_value);
            users.push(_to);
            Transfer(msg.sender, _to, _value);
        }
   
        function transferFrom(address _from, address _to, uint256 _value) public  {
            require(balances[_from] >= _value);
            require(allowed[_from][msg.sender] >= _value);
            require(balances[_to] + _value > balances[_to]);
          
            balances[_to]=balances[_to].add(_value);
            balances[_from]=balances[_from].sub(_value);
            allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
        }
        
    
    function changeAdmin(address _newAdmin) public onlyOwner returns (bool)  {
        require(_newAdmin != address(0));
        
        emit Transfer(platformAdmin,_newAdmin,balances[platformAdmin]);
        
        balances[_newAdmin] = balances[_newAdmin].add(balances[platformAdmin]);
        balances[platformAdmin] = 0;
        platformAdmin = _newAdmin;
        return true;
    }

   function generateToken( uint256 _amount ) public onlyOwner returns (bool)  {
        balances[platformAdmin] = balances[platformAdmin].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
        return true;
    }
   
   


    function multiWithdraw (address[] users,uint256[] _amount)public onlyOwner returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            users[i].transfer(_amount[i]);
        }
        return true;
    }
    
    function multiWithdrawToken (address _tokenAddress,address[] users,uint256[] _tokenAmount)public onlyOwner returns (bool) {
         ERC20 token =ERC20(_tokenAddress);
         for (uint256 i = 0; i < users.length; i++) {
             token.transfer(users[i],_tokenAmount[i]);
         }
        return true;
    }
   

    function freeze(address _target,bool _freeze) public onlyOwner returns (bool) {
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }

    function freezeWithTimestamp(address _target,uint256 _timestamp)public onlyOwner returns (bool) {
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }


    function multiFreeze(address[] _targets,bool[] _freezes) public onlyOwner returns (bool) {
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i++) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }

    function multiFreezeWithTimestamp( address[] _targets,uint256[] _timestamps) public onlyOwner returns (bool) {
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i++) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }

    function multiTransfer( address[] _tos, uint256[] _values)public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i++) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j++) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }
    
    
     function getFrozenTimestamp(address _target) public view returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }

    function getFrozenAccount(address _target)public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
 
    function getTokenAllowance(address _tokenAddress,address _owner, address _spender) public constant returns (uint) {
         ERC20 token =ERC20(_tokenAddress);
         uint allowed=token.allowance(_owner,_spender);
         return allowed;
    }
    
    function getTokenDecimals(address _tokenAddress) public constant returns (uint) {
         ERC20 token =ERC20(_tokenAddress);
         uint decimals=token.decimals();
         return decimals;
    }
    
    function getTokenBalance(address _tokenAddress) public constant returns (uint) {
             ERC20 token =ERC20(_tokenAddress);
             uint balance=token.balanceOf(this);
             return balance;
    }

     function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function exChangeToken(address _tokenAddress,uint256 _tokenAmount) public{
        require(tokenRateArray[_tokenAddress]>0);
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require (!tokenExchangeLock[_tokenAddress]) ;
        require(now>startTime&&now<endTime);

        uint256 amount;
         ERC20 token =ERC20(_tokenAddress);
         uint deci=token.decimals();
         if(tokenRateSignArray[_tokenAddress]==1){
             if(decimals>deci){
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]).mul(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]).div(10 ** (deci.sub(decimals)));
             }else{
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]);
             }
         }else  if(tokenRateSignArray[_tokenAddress]==2){
             if(decimals>deci){
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]).mul(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]).div(10 ** (deci.sub(decimals)));
             }else{
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]);
             }
         }else{
             throw;
         }
        require(amount>0&&amount <= balances[platformAdmin]);
         
         require(_tokenAmount <= token.balanceOf(msg.sender));
         token.transferFrom(msg.sender,this,_tokenAmount);
        
        balances[platformAdmin] = balances[platformAdmin].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
 
        emit Transfer(platformAdmin, msg.sender, amount);
    }
    
}