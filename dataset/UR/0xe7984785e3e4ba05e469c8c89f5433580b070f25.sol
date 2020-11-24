 

pragma solidity ^0.5.3;

     
     
     
    contract Owned {
        address public owner;
        address public newOwner;

        event OwnershipTransferred(address indexed _from, address indexed _to);

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address _newOwner) public onlyOwner {
            newOwner = _newOwner;
        }
        function acceptOwnership() public {
            require(msg.sender == newOwner);
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            newOwner = address(0);
        }
    }

     
     
     
    library SafeMath {
        function add(uint a, uint b) internal pure returns (uint c) {
            c = a + b;
            require(c >= a);
        }
        function sub(uint a, uint b) internal pure returns (uint c) {
            require(b <= a);
            c = a - b;
        }
        function mul(uint a, uint b) internal pure returns (uint c) {
            c = a * b;
            require(a == 0 || c / a == b);
        }
        function div(uint a, uint b) internal pure returns (uint c) {
            require(b > 0);
            c = a / b;
        }
    }

     
     
     
    contract ERC20Interface {
        function totalSupply() public view returns (uint);
        function balanceOf(address tokenOwner) public view returns (uint balance);
        function allowance(address tokenOwner, address spender) public view returns (uint remaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address from, address to, uint tokens) public returns (bool success);

        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }

     
     
     
    contract VT is ERC20Interface, Owned{
        using SafeMath for uint;
        
        string public symbol;
        string public name;
        uint8 public decimals;
        uint _totalSupply;
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        mapping(address => uint) unLockedCoins;  
        struct PC {
        uint256 lockingPeriod;
        uint256 coins;
        bool added;
        }
        mapping(address => PC[]) record;  

         
         
         
        constructor(address _owner) public{
            symbol = "VT";
            name = "VT";
            decimals = 18;
            owner = _owner;
            _totalSupply = 1e9;  
            balances[owner] = totalSupply();
            emit Transfer(address(0),owner,totalSupply());
        }

        function totalSupply() public view returns (uint){
        return _totalSupply * 10**uint(decimals);
        }

         
         
         
        function balanceOf(address tokenOwner) public view returns (uint balance) {
            return balances[tokenOwner];
        }

         
         
         
         
         
        function transfer(address to, uint tokens) public returns (bool success) {
             
            if(msg.sender != owner){
                _updateUnLockedCoins(msg.sender, tokens);
                unLockedCoins[msg.sender] = unLockedCoins[msg.sender].sub(tokens);
                unLockedCoins[to] = unLockedCoins[to].add(tokens);
            }
             
            require(to != address(0));
            require(balances[msg.sender] >= tokens );
            require(balances[to] + tokens >= balances[to]);
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender,to,tokens);
            return true;
        }
        
         
         
         
         
        function approve(address spender, uint tokens) public returns (bool success){
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender,spender,tokens);
            return true;
        }

         
         
         
         
         
         
         
         
         
        function transferFrom(address from, address to, uint tokens) public returns (bool success){
             
            if(msg.sender != owner){
                _updateUnLockedCoins(from, tokens);
                unLockedCoins[from] = unLockedCoins[from].sub(tokens);
                unLockedCoins[to] = unLockedCoins[to].add(tokens);
            }
            require(tokens <= allowed[from][msg.sender]);  
            require(balances[from] >= tokens);
            balances[from] = balances[from].sub(tokens);
            balances[to] = balances[to].add(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            emit Transfer(from,to,tokens);
            return true;
        }
         
         
         
         
        function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }
        
         
         
         
         
         
         
         
        function distributeTokens(address to, uint tokens, uint256 lockingPeriod) onlyOwner public returns (bool success) {
             
            transfer(to, tokens);
             
            if(lockingPeriod == 0)
                unLockedCoins[to] = unLockedCoins[to].add(tokens);
             
            else
                _addRecord(to, tokens, lockingPeriod);
            return true;
        }
        
         
         
         
        function _addRecord(address to, uint tokens, uint256 lockingPeriod) private {
                record[to].push(PC(lockingPeriod,tokens, false));
        }
        
         
         
         
        function _updateUnLockedCoins(address _from, uint tokens) private returns (bool success) {
             
            if(unLockedCoins[_from] >= tokens){
                return true;
            }
             
            else{
                _updateRecord(_from);
                 
                if(unLockedCoins[_from] >= tokens){
                    return true;
                }
                 
                else{
                    revert();
                }
            }
        }
        
         
         
         
        function _updateRecord(address _address) private returns (bool success){
            PC[] memory tempArray = record[_address];
            uint tempCount = 0;
            for(uint i=0; i < tempArray.length; i++){
                if(tempArray[i].lockingPeriod < now && tempArray[i].added == false){
                    tempCount = tempCount.add(tempArray[i].coins);
                    tempArray[i].added = true;
                    record[_address][i] = PC(tempArray[i].lockingPeriod, tempArray[i].coins, tempArray[i].added);
                }
            }
            unLockedCoins[_address] = unLockedCoins[_address].add(tempCount);
            return true;
        }
        
    }