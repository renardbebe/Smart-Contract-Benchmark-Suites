 

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
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _postTransferHook(msg.sender, _to, _value);

        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function _postTransferHook(address _from, address _to, uint256 _value) internal;
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        _postTransferHook(_from, _to, _value);

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

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function Owned() public {
        owner = msg.sender;
    }
}


contract AcceptsTokens {
    ETToken public tokenContract;

    function AcceptsTokens(address _tokenContract) public {
        tokenContract = ETToken(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    function acceptTokens(address _from, uint256 _value, uint256 param1, uint256 param2, uint256 param3) external;
}

contract ETToken is Owned, StandardToken {
    using SafeMath for uint;

    string public name = "ETH.TOWN Token";
    string public symbol = "ETIT";
    uint8 public decimals = 18;

    address public beneficiary;
    address public oracle;
    address public heroContract;
    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    mapping (uint32 => address) public floorContracts;
    mapping (address => bool) public canAcceptTokens;

    mapping (address => bool) public isMinter;

    modifier onlyMinters {
        require(msg.sender == owner || isMinter[msg.sender]);
        _;
    }

    event Dividend(uint256 value);
    event Withdrawal(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function ETToken() public {
        oracle = owner;
        beneficiary = owner;

        totalSupply_ = 0;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }
    function setHeroContract(address _heroContract) external onlyOwner {
        heroContract = _heroContract;
    }

    function _mintTokens(address _user, uint256 _amount) private {
        require(_user != 0x0);

        balances[_user] = balances[_user].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);

        emit Transfer(address(this), _user, _amount);
    }

    function authorizeFloor(uint32 _index, address _floorContract) external onlyOwner {
        floorContracts[_index] = _floorContract;
    }

    function _acceptDividends(uint256 _value) internal {
        uint256 beneficiaryShare = _value / 5;
        uint256 poolShare = _value.sub(beneficiaryShare);

        beneficiary.transfer(beneficiaryShare);

        emit Dividend(poolShare);
    }

    function acceptDividends(uint256 _value, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _acceptDividends(_value);
    }

    function rewardTokensFloor(address _user, uint256 _tokens, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _mintTokens(_user, _tokens);
    }

    function rewardTokens(address _user, uint256 _tokens) external onlyMinters {
        _mintTokens(_user, _tokens);
    }

    function() payable public {
         
    }

    function payoutDividends(address _user, uint256 _value) external onlyOracle {
        _user.transfer(_value);

        emit Withdrawal(_user, _value);
    }

    function accountAuth(uint256  ) external {
         
    }

    function burn(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);

        emit Burn(msg.sender, _amount);
    }

    function setCanAcceptTokens(address _address, bool _value) external onlyOwner {
        canAcceptTokens[_address] = _value;
    }

    function setIsMinter(address _address, bool _value) external onlyOwner {
        isMinter[_address] = _value;
    }

    function _invokeTokenRecipient(address _from, address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) internal {
        if (!canAcceptTokens[_to]) {
            return;
        }

        AcceptsTokens recipient = AcceptsTokens(_to);

        recipient.acceptTokens(_from, _value, _param1, _param2, _param3);
    }

     
    function transferWithParams(address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) onlyPayloadSize(5 * 32) external returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _invokeTokenRecipient(msg.sender, _to, _value, _param1, _param2, _param3);

        return true;
    }

     
    function _postTransferHook(address _from, address _to, uint256 _value) internal {
        _invokeTokenRecipient(_from, _to, _value, 0, 0, 0);
    }


}

contract PresaleContract is Owned {
    ETToken public tokenContract;

     
    function PresaleContract(address _tokenContract) public {
        tokenContract = ETToken(_tokenContract);
    }
}

contract ETCharPresale_v2 is PresaleContract {
    using SafeMath for uint;

    bool public enabled = true;
    uint32 public maxCharId = 10000;
    uint32 public currentCharId = 2000;

    uint256 public currentPrice = 0.02 ether;

    mapping (uint32 => address) public owners;
    mapping (address => uint32[]) public characters;

    bool public awardTokens = true;

    event Purchase(address from, uint32 charId, uint256 amount);

    function ETCharPresale_v2(address _presaleToken)
    PresaleContract(_presaleToken)
    public
    {
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function _provideChars(address _address, uint32 _number) internal {

        for (uint32 i = 0; i < _number; i++) {
            owners[currentCharId + i] = _address;
            characters[_address].push(currentCharId + i);
            emit Purchase(_address, currentCharId + i, currentPrice);
        }

        currentCharId += _number;
        currentPrice += priceIncrease() * _number;
    }

    function priceIncrease() public view returns (uint256) {
        uint256 _currentPrice = currentPrice;

        if (_currentPrice > 0.0425 ether) {
            return 0.00078125 finney;
        } else {
            return 0.028 finney;
        }
    }

    function() public payable {
        require(enabled);
        require(!_isContract(msg.sender));

        require(msg.value >= currentPrice);

        uint32 chars = uint32(msg.value.div(currentPrice));

        require(chars <= 100);

        if (chars > 50) {
            chars = 50;
        }

        require(currentCharId + chars - 1 <= maxCharId);

        uint256 purchaseValue = currentPrice.mul(chars);
        uint256 change = msg.value.sub(purchaseValue);

        _provideChars(msg.sender, chars);

        if (awardTokens) {
            tokenContract.rewardTokens(msg.sender, purchaseValue * 200);
        }

        if (currentCharId > maxCharId) {
            enabled = false;
        }

        if (change > 0) {
            msg.sender.transfer(change);
        }
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setMaxCharId(uint32 _maxCharId) public onlyOwner {
        maxCharId = _maxCharId;
    }

    function setCurrentPrice(uint256 _currentPrice) public onlyOwner {
        currentPrice = _currentPrice;
    }

    function setAwardTokens(bool _awardTokens) public onlyOwner {
        awardTokens = _awardTokens;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function charactersOf(address _user) public view returns (uint32[]) {
        return characters[_user];
    }

    function charactersCountOf(address _user) public view returns (uint256) {
        return characters[_user].length;
    }

    function getCharacter(address _user, uint256 _index) public view returns (uint32) {
        return characters[_user][_index];
    }

}