 

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

contract Destroyable is Ownable{
     
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address who) view external returns (uint256);
}

contract Airdrop is Ownable, Destroyable {
    using SafeMath for uint256;

     
     
    struct Beneficiary {
        uint256 balance;
        uint256 airdrop;
        bool isBeneficiary;
    }

     
    bool public filled;
    bool public airdropped;
    uint256 public airdropLimit;
    uint256 public currentCirculating;
    uint256 public burn;
    address public hell;
    address[] public addresses;
    Token public token;
    mapping(address => Beneficiary) public beneficiaries;


     
    event NewBeneficiary(address _beneficiary);
    event SnapshotTaken(uint256 _totalBalance, uint256 _totalAirdrop, uint256 _toBurn,uint256 _numberOfBeneficiaries, uint256 _numberOfAirdrops);
    event Airdropped(uint256 _totalAirdrop, uint256 _numberOfAirdrops);
    event TokenChanged(address _prevToken, address _token);
    event AirdropLimitChanged(uint256 _prevLimit, uint256 _airdropLimit);
    event CurrentCirculatingChanged(uint256 _prevCirculating, uint256 _currentCirculating);
    event Cleaned(uint256 _numberOfBeneficiaries);
    event Burned(uint256 _tokensBurned);

     
    modifier isNotBeneficiary(address _beneficiary) {
        require(!beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isFilled() {
        require(filled);
        _;
    }
    modifier isNotFilled() {
        require(!filled);
        _;
    }
    modifier wasAirdropped() {
        require(airdropped);
        _;
    }
    modifier wasNotAirdropped() {
        require(!airdropped);
        _;
    }

     

     
    function Airdrop(address _token, uint256 _airdropLimit, uint256 _currentCirculating, address _hell) public{
        require(_token != address(0));
        token = Token(_token);
        airdropLimit = _airdropLimit;
        currentCirculating = _currentCirculating;
        hell = _hell;
    }

     
    function() payable public {
        addBeneficiary(msg.sender);
    }


     
    function register() public {
        addBeneficiary(msg.sender);
    }

     
    function registerBeneficiary(address _beneficiary) public
    onlyOwner {
        addBeneficiary(_beneficiary);
    }

     
    function registerBeneficiaries(address[] _beneficiaries) public
    onlyOwner {
        for (uint i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i]);
        }
    }

     
    function addBeneficiary(address _beneficiary) private
    isNotBeneficiary(_beneficiary) {
        require(_beneficiary != address(0));
        beneficiaries[_beneficiary] = Beneficiary({
            balance : 0,
            airdrop : 0,
            isBeneficiary : true
            });
        addresses.push(_beneficiary);
        emit NewBeneficiary(_beneficiary);
    }

     
    function takeSnapshot() public
    onlyOwner
    isNotFilled
    wasNotAirdropped {
        uint256 totalBalance = 0;
        uint256 totalAirdrop = 0;
        uint256 airdrops = 0;
        for (uint i = 0; i < addresses.length; i++) {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.balance = token.balanceOf(addresses[i]);
            totalBalance = totalBalance.add(beneficiary.balance);
            if (beneficiary.balance > 0) {
                beneficiary.airdrop = (beneficiary.balance.mul(airdropLimit).div(currentCirculating));
                totalAirdrop = totalAirdrop.add(beneficiary.airdrop);
                airdrops = airdrops.add(1);
            }
        }
        filled = true;
        burn = airdropLimit.sub(totalAirdrop);
        emit SnapshotTaken(totalBalance, totalAirdrop, burn, addresses.length, airdrops);
    }

     
    function airdropAndBurn() public
    onlyOwner
    isFilled
    wasNotAirdropped {
        uint256 airdrops = 0;
        uint256 totalAirdrop = 0;
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            if (beneficiary.airdrop > 0) {
                require(token.transfer(addresses[i], beneficiary.airdrop));
                totalAirdrop = totalAirdrop.add(beneficiary.airdrop);
                airdrops = airdrops.add(1);
            }
        }
        airdropped = true;
        currentCirculating = currentCirculating.add(totalAirdrop);
        emit Airdropped(totalAirdrop, airdrops);
        emit Burned(burn);
        token.transfer(hell, burn);

    }

     
    function clean() public
    onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.balance = 0;
            beneficiary.airdrop = 0;
        }
        filled = false;
        airdropped = false;
        burn = 0;
        emit Cleaned(addresses.length);
    }

     
    function changeToken(address _token) public
    onlyOwner {
        emit TokenChanged(address(token), _token);
        token = Token(_token);
    }

     
    function changeAirdropLimit(uint256 _airdropLimit) public
    onlyOwner {
        emit AirdropLimitChanged(airdropLimit, _airdropLimit);
        airdropLimit = _airdropLimit;
    }

     
    function changeCurrentCirculating(uint256 _currentCirculating) public
    onlyOwner {
        emit CurrentCirculatingChanged(currentCirculating, _currentCirculating);
        currentCirculating = _currentCirculating;
    }

     
    function flushEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function flushTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

     
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
        selfdestruct(owner);
    }

     
    function tokenBalance() view public returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

     
    function getBalanceAtSnapshot(address _beneficiary) view public returns (uint256 _balance) {
        return beneficiaries[_beneficiary].balance / 1 ether;
    }

     
    function getAirdropAtSnapshot(address _beneficiary) view public returns (uint256 _airdrop) {
        return beneficiaries[_beneficiary].airdrop / 1 ether;
    }

     
    function amIBeneficiary(address _beneficiary) view public returns (bool _isBeneficiary) {
        return beneficiaries[_beneficiary].isBeneficiary;
    }

     
    function beneficiariesLength() view public returns (uint256 _length) {
        return addresses.length;
    }
}