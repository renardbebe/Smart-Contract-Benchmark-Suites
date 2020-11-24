 

pragma solidity ^0.4.21;

 
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


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}



 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 

contract MintableToken is StandardToken, Ownable, BurnableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    
}

contract ElepigToken is MintableToken {
    string public name = "Elepig";
    string public symbol = "EPG";
    uint8 public decimals = 18;    

    
    uint constant unlockY1Time = 1546300800;  
    uint constant unlockY2Time = 1577836800;  
    uint constant unlockY3Time = 1609459200;  
    uint constant unlockY4Time = 1640995200;  
         
    mapping (address => uint256) public freezeOf;
    
    address affiliate;
    address contingency;
    address advisor;  

     
    address team; 
    address teamY1; 
    address teamY2; 
    address teamY3; 
    address teamY4; 
    bool public mintedWallets = false;
    
     
     
     

    uint256 constant affiliateTokens = 7500000000000000000000000;       
    uint256 constant contingencyTokens = 52500000000000000000000000;    
    uint256 constant advisorTokens = 30000000000000000000000000;        
    uint256 constant teamTokensPerWallet = 12000000000000000000000000;   

    
   
    event Unfreeze(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event WalletsMinted();


     
    function ElepigToken() public {
        
    }
    
     
    function mintWallets(                
        address _affiliateAddress, 
        address _contingencyAddress, 
        address _advisorAddress,         
        address _teamAddress, 
        address _teamY1Address, 
        address _teamY2Address, 
        address _teamY3Address, 
        address _teamY4Address
        ) public  onlyOwner {  
        require(_affiliateAddress != address(0));
        require(_contingencyAddress != address(0));
        require(_advisorAddress != address(0));
        require(_teamAddress != address(0));
        require(_teamY1Address != address(0));
        require(_teamY2Address != address(0));
        require(_teamY3Address != address(0));
        require(_teamY4Address != address(0)); 
        require(mintedWallets == false);  
        
            
        affiliate = _affiliateAddress;
        contingency = _contingencyAddress;
        advisor = _advisorAddress;

         
        team = _teamAddress;
        teamY1 = _teamY1Address;
        teamY2 = _teamY2Address;
        teamY3 = _teamY3Address;
        teamY4 = _teamY4Address;
        
         
        mint(affiliate, affiliateTokens);
        mint(contingency, contingencyTokens);
        mint(advisor, advisorTokens);
        mint(team, teamTokensPerWallet);
        mint(teamY1, teamTokensPerWallet);  
        mint(teamY2, teamTokensPerWallet);  
        mint(teamY3, teamTokensPerWallet);  
        mint(teamY4, teamTokensPerWallet);  

        mintedWallets = true;
        emit WalletsMinted();
    }

    function checkPermissions(address _from) internal view returns (bool) {        
         
        if (_from == teamY1 && now < unlockY1Time) {
            return false;
        } else if (_from == teamY2 && now < unlockY2Time) {
            return false;
        } else if (_from == teamY3 && now < unlockY3Time) {
            return false;
        } else if (_from == teamY4 && now < unlockY4Time) {
            return false;
        } else {
         
            return true;
        } 
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
    }

    function freeze(uint256 _value) public returns (bool success) {     
        require(balances[msg.sender] < _value);  
        require(_value <= 0);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);           
        freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);           
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] < _value);  
        require(_value <= 0);
        
        freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender], _value);            
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function () public payable {
        revert();
    }
}