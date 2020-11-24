 

pragma solidity ^0.4.24;
 
 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}
 
 contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}
 

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}
 
contract NTechToken is ERC20, Ownable, Pausable{
     
    string public                   name = "NTech";
    string public                   symbol = "NT";
    uint8 constant public           decimals = 18;
    uint256                         supply;

    mapping (address => uint256)                        balances;
    mapping (address => mapping (address => uint256))   approvals;
    uint256 public constant initSupply = 10000000000;        

    constructor() public {
        supply = SafeMath.mul(uint256(initSupply),uint256(10)**uint256(decimals));
        balances[msg.sender] = supply; 
    }
     
    function totalSupply() public view returns (uint256){
        return supply ;
    }

    function balanceOf(address src) public view returns (uint256) {
        return balances[src];
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return approvals[src][guy];
    }
    
    function transfer(address dst, uint wad) whenNotPaused public returns (bool) {
        require(balances[msg.sender] >= wad);                    
        require(dst != 0x0);                                     

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], wad);   
        balances[dst] = SafeMath.add(balances[dst], wad);                 
        
        emit Transfer(msg.sender, dst, wad);                     
        
        return true;
    }

    function transferFrom(address src, address dst, uint wad) whenNotPaused public returns (bool) {
        require(balances[src] >= wad);                           
        require(approvals[src][msg.sender] >= wad);
        
        approvals[src][msg.sender] = SafeMath.sub(approvals[src][msg.sender], wad);
        balances[src] = SafeMath.sub(balances[src], wad);
        balances[dst] = SafeMath.add(balances[dst], wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) whenNotPaused public returns (bool) {
        require(wad != 0);
        approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    
}