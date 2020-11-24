 

pragma solidity >=0.4.22 <0.6.0;

     
     
     
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

     
     
     
    contract KADO is ERC20Interface{
        using SafeMath for uint;
        
        string public symbol;
        string public name;
        uint8 public decimals;
        uint _totalSupply;
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;

         
         
         
        constructor(address _owner) public{
            symbol = "KADO";
            name = "Kado Token";
            decimals = 18;
            _totalSupply = 30e8;  
            balances[_owner] = totalSupply();
            emit Transfer(address(0),_owner,totalSupply());
        }

        function totalSupply() public view returns (uint){
        return _totalSupply * 10**uint(decimals);
        }

         
         
         
        function balanceOf(address tokenOwner) public view returns (uint balance) {
            return balances[tokenOwner];
        }

         
         
         
         
         
        function transfer(address to, uint tokens) public returns (bool success) {
             
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
    }