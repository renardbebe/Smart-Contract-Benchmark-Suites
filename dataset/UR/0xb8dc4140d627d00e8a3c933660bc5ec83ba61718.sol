 

pragma solidity 0.4.21;

library SafeMath {
     
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract Owned {
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function Owned() public {
        owner = msg.sender;
    }
}

 
 
contract SimpleToken is Owned {
    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;
     
    uint256 public totalSupply;

     
    string public name = "CryptoGold";           
    string public symbol = "CGC" ;              
    uint8 public decimals = 6;                 

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

}

 
 
contract MultiSigMint is SimpleToken {

     
    event newOwner(address indexed oldAddress, address indexed newAddress);
    event newNotary(address indexed oldAddress, address indexed newAddress);    
    event Mint(address indexed minter, uint256 value);
    event Burn(address indexed burner, uint256 value);

     
    address public notary;

    uint256 proposedMintAmnt = 0;
    uint256 proposedBurnAmnt = 0;

    address proposeOwner = 0x0;
    address proposeNotary = 0x0;

    function MultiSigMint(address _notary) public {
        require(_notary != 0x0);
        require(msg.sender != _notary);
        notary = _notary;
    }

    modifier onlyNotary {
        require(msg.sender == notary);
        _;
    }

     
    function proposeMinting(uint256 _tokenamount) external onlyOwner returns (bool) {
        require(_tokenamount > 0);
        proposedMintAmnt = _tokenamount;
        return true;
    }

     
    function confirmMinting(uint256 _tokenamount) external onlyNotary returns (bool) {
        if (_tokenamount == proposedMintAmnt) {
            proposedMintAmnt = 0;  
            balanceOf[owner] = balanceOf[owner].add(_tokenamount);
            totalSupply = totalSupply.add(_tokenamount);
            emit Mint(owner, _tokenamount);
            emit Transfer(0x0, owner, _tokenamount);
            return true;
        } else {
            proposedMintAmnt = 0;  
            return false;
        }
    }

     
    function proposeBurning(uint256 _tokenamount) external onlyOwner returns (bool) {
        require(_tokenamount > 0);
        proposedBurnAmnt = _tokenamount;
        return true;
    }

     
    function confirmBurning(uint256 _tokenamount) external onlyNotary returns (bool) {
        if (_tokenamount == proposedBurnAmnt) {
            proposedBurnAmnt = 0;  
            balanceOf[owner] = balanceOf[owner].sub(_tokenamount);
            totalSupply = totalSupply.sub(_tokenamount);
            emit Burn(owner, _tokenamount);
            emit Transfer(owner, 0x0, _tokenamount);
            return true;
        } else {
            proposedBurnAmnt = 0;  
            return false;
        }
    }

     
    function proposeNewOwner(address _newAddress) external onlyOwner {
        proposeOwner = _newAddress;
    }
    function confirmNewOwner(address _newAddress) external onlyNotary returns (bool) {
        if (proposeOwner == _newAddress && _newAddress != 0x0 && _newAddress != notary) {
            proposeOwner = 0x0;
            emit newOwner(owner, _newAddress);
            owner = _newAddress;
            return true;
        } else {
            proposeOwner = 0x0;
            return false;
        }
    }
    
     
    function proposeNewNotary(address _newAddress) external onlyOwner {
        proposeNotary = _newAddress;
    }
    function confirmNewNotary(address _newAddress) external onlyNotary returns (bool) {
        if (proposeNotary == _newAddress && _newAddress != 0x0 && _newAddress != owner) {
            proposeNotary = 0x0;
            emit newNotary(notary, _newAddress);
            notary = _newAddress;
            return true;
        } else {
            proposeNotary = 0x0;
            return false;
        }
    }
}

 
 
contract GoldToken is MultiSigMint {
    function GoldToken(address _notary) public MultiSigMint(_notary) {}
}