 

 

 

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

 
    contract token {
       
     
            string public name;
            string public symbol;
            uint256 public decimals = 8;  
            uint256 public _totalSupply; 
            uint256 public startTime=1567958400;
 
        function totalSupply() constant returns (uint256 supply) {
            return _totalSupply;
        }
 
        function changeStartTime(uint256 _startTime) returns (bool success) {
            require(msg.sender==founder);
            startTime=_startTime;
            return true;
        }
 
        function approve(address _spender, uint256 _value) returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        
 
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
 
        mapping(address => uint256) public  balanceOf;         
        mapping(address => uint256) public distBalances;
        
        mapping(address => bool) public distTeam;
        
           
        mapping(address => bool) public lockAddrs;           
        mapping(address => mapping (address => uint256)) allowed;
 
 
        address public founder;
        uint256 public distributed = 0;
 
        event AllocateFounderTokens(address indexed sender);
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
      
 
    function token(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        founder = msg.sender;
        _totalSupply = initialSupply * 10 ** uint256(decimals); 
        name = tokenName;
        symbol = tokenSymbol;
        balanceOf[msg.sender]=_totalSupply;
    }
 

        
     
        function lockAddr(address user) returns (bool success) {
            if (msg.sender != founder) revert();
            lockAddrs[user]=true;
            return true;
        }
        
      
        function unLockAddr(address user) returns (bool success) {
            if (msg.sender != founder) revert();
            lockAddrs[user]=false;
            return true;
        }
 

        function distribute(uint256 _amount, address[] _to,bool isteam) {
            if (msg.sender!=founder) revert();
            if (SafeMath.add(distributed,SafeMath.mul(_to.length,_amount)) > _totalSupply) revert();
            
            for(uint j=0;j<_to.length;j++){
                if(distBalances[_to[j]]>0) revert();
            }
            
            for(uint i=0;i<_to.length;i++){
                distributed= SafeMath.add(distributed, _amount);
                distBalances[_to[i]] =SafeMath.add(distBalances[_to[i]], _amount);
                if(isteam){
                    distTeam[_to[i]]=true;
                }
                transfer(_to[i],_amount);
             }
           
        }
        
        function transfer(address _to, uint256 _value) public {
 
            require(lockAddrs[msg.sender]==false);
            require(balanceOf[msg.sender] >= _value);
            require(SafeMath.add(balanceOf[_to],_value) > balanceOf[_to]);
          
            uint _freeAmount = freeAmount(msg.sender);
            require (_freeAmount > _value);

            balanceOf[msg.sender]=SafeMath.sub(balanceOf[msg.sender], _value);
            balanceOf[_to]=SafeMath.add(balanceOf[_to], _value);
            Transfer(msg.sender, _to, _value);
        }
        
    
       
        function freeAmount(address user) constant  returns (uint256 amount) {
          
            if (user == founder) {
                return balanceOf[user];
            }
            uint monthDiff;
            bool isteam;
            if(distTeam[user]){
                isteam=true;
            }
            if(startTime<now){
               if(isteam){
                     monthDiff= (now-startTime) / 90 days;
                    if(monthDiff==0){
                        return  balanceOf[user]-distBalances[user];
                    }else if(monthDiff>0 && monthDiff<12){
                        return  distBalances[user]/12*monthDiff+balanceOf[user]-distBalances[user];
                    }else{
                        return distBalances[user]+balanceOf[user]-distBalances[user];
                    }
               }else{
                    uint256 direct=distBalances[user]/10;
                     monthDiff= (now-startTime) /30 days;
                    if(monthDiff==0){
                        return  direct+balanceOf[user]-distBalances[user];
                    }else if(monthDiff>0 && monthDiff<4){
                        return  direct+(distBalances[user]-direct)/4*monthDiff+balanceOf[user]-distBalances[user];
                    }else{
                        return distBalances[user]+balanceOf[user]-distBalances[user];
                    }
               }
            }else{
                return balanceOf[user]-distBalances[user];
            }
        }
 
        
       function unLockAmount(address user) constant returns (uint256 amount) {
 
            uint monthDiff;
            bool isteam;
            if(distTeam[user]){
                isteam=true;
            }
            if(startTime<now){
                if(isteam){
                        monthDiff= (now-startTime) / 90 days;
                        if(monthDiff==0){
                            return  0;
                        }else if(monthDiff>0 && monthDiff<12){
                            return  distBalances[user]/12*monthDiff;
                        }else{
                            return distBalances[user];
                        }
                }else{
                        uint256 direct=distBalances[user]/10;
                        monthDiff= (now-startTime)/30 days;
                        if(monthDiff==0){
                            return  direct;
                        }else if(monthDiff>0 && monthDiff<4){
                            return  direct+(distBalances[user]-direct)/4*monthDiff;
                        }else{
                            return distBalances[user];
                        }
                }
            }else{
                return 0;
            }
        }
 

        function changeFounder(address newFounder) {
            if (msg.sender!=founder) revert();
            founder = newFounder; 
        }
 
   
        function transferFrom(address _from, address _to, uint256 _value) {
         
            require(lockAddrs[_from]==false);
            require(balanceOf[_from] >= _value);
            require(allowed[_from][msg.sender] >= _value);
            require(balanceOf[_to] + _value > balanceOf[_to]);
          
            uint _freeAmount = freeAmount(_from);
            require (_freeAmount > _value);
            
            balanceOf[_to]=SafeMath.add(balanceOf[_to],_value);
            balanceOf[_from]=SafeMath.sub(balanceOf[_from],_value);
            allowed[_from][msg.sender]=SafeMath.sub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);

        }
 
        function() payable {
            if (!founder.call.value(msg.value)()) revert(); 
        }
    }