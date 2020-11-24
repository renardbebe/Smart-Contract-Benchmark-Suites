 

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



contract ETPotatoPresale is PresaleContract {
    using SafeMath for uint;

    uint256 public auctionEnd;
    uint256 public itemType;

    address public highestBidder;
    uint256 public highestBid = 0.001 ether;
    bool public ended;

    event Bid(address from, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    function ETPotatoPresale(address _presaleToken, uint256 _auctionEnd, uint256 _itemType)
        PresaleContract(_presaleToken)
        public
    {
        auctionEnd = _auctionEnd;
        itemType = _itemType;
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function auctionExpired() public view returns (bool) {
        return now > auctionEnd;
    }

    function nextBid() public view returns (uint256) {
        if (highestBid < 0.1 ether) {
            return highestBid.add(highestBid / 2);
        } else if (highestBid < 1 ether) {
            return highestBid.add(highestBid.mul(15).div(100));
        } else {
            return highestBid.add(highestBid.mul(8).div(100));
        }
    }

    function() public payable {
        require(!_isContract(msg.sender));
        require(!auctionExpired());

        uint256 requiredBid = nextBid();

        require(msg.value >= requiredBid);

        uint256 change = msg.value.sub(requiredBid);

        uint256 difference = requiredBid.sub(highestBid);
        uint256 reward = difference / 4;

        if (highestBidder != 0x0) {
            highestBidder.transfer(highestBid.add(reward));
        }

        if (change > 0) {
            msg.sender.transfer(change);
        }

        highestBidder = msg.sender;
        highestBid = requiredBid;

        emit Bid(msg.sender, requiredBid);
    }

    function endAuction() public onlyOwner {
        require(auctionExpired());
        require(!ended);

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        tokenContract.rewardTokens(highestBidder, highestBid * 200);

        owner.transfer(address(this).balance);
    }
}