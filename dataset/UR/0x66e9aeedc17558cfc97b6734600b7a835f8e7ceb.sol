 

pragma solidity ^0.4.18;
 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Destroyable is Ownable{
     
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

interface Token {
    function transfer(address _to, uint256 _value) public;

    function balanceOf(address who) public returns (uint256);
}

contract MultiVesting is Ownable, Destroyable {
    using SafeMath for uint256;

     
    struct Beneficiary {
        uint256 released;
        uint256 vested;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        bool revoked;
        bool revocable;
        bool isBeneficiary;
    }

    event Released(address _beneficiary, uint256 amount);
    event Revoked(address _beneficiary);
    event NewBeneficiary(address _beneficiary);
    event BeneficiaryDestroyed(address _beneficiary);


    mapping(address => Beneficiary) public beneficiaries;
    Token public token;
    uint256 public totalVested;
    uint256 public totalReleased;

     
    modifier isNotBeneficiary(address _beneficiary) {
        require(!beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].isBeneficiary);
        _;
    }

    modifier wasRevoked(address _beneficiary) {
        require(beneficiaries[_beneficiary].revoked);
        _;
    }

    modifier wasNotRevoked(address _beneficiary) {
        require(!beneficiaries[_beneficiary].revoked);
        _;
    }

     
    function MultiVesting(address _token) public {
        require(_token != address(0));
        token = Token(_token);
    }

    function() payable public {
        release(msg.sender);
    }

     
    function release() public {
        release(msg.sender);
    }

     
    function release(address _beneficiary) private
    isBeneficiary(_beneficiary)
    {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];

        uint256 unreleased = releasableAmount(_beneficiary);

        require(unreleased > 0);

        beneficiary.released = beneficiary.released.add(unreleased);

        totalReleased = totalReleased.add(unreleased);

        token.transfer(_beneficiary, unreleased);

        if((beneficiary.vested - beneficiary.released) == 0){
            beneficiary.isBeneficiary = false;
        }

        Released(_beneficiary, unreleased);
    }

     
    function releaseTo(address _beneficiary) public onlyOwner {
        release(_beneficiary);
    }

     
    function addBeneficiary(address _beneficiary, uint256 _vested, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable)
    onlyOwner
    isNotBeneficiary(_beneficiary)
    public {
        require(_beneficiary != address(0));
        require(_cliff >= _start);
        require(token.balanceOf(this) >= totalVested.sub(totalReleased).add(_vested));
        beneficiaries[_beneficiary] = Beneficiary({
            released : 0,
            vested : _vested,
            start : _start,
            cliff : _cliff,
            duration : _duration,
            revoked : false,
            revocable : _revocable,
            isBeneficiary : true
            });
        totalVested = totalVested.add(_vested);
        NewBeneficiary(_beneficiary);
    }

     
    function revoke(address _beneficiary) public onlyOwner {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        require(beneficiary.revocable);
        require(!beneficiary.revoked);

        uint256 balance = beneficiary.vested.sub(beneficiary.released);

        uint256 unreleased = releasableAmount(_beneficiary);
        uint256 refund = balance.sub(unreleased);

        token.transfer(owner, refund);

        totalReleased = totalReleased.add(refund);

        beneficiary.revoked = true;
        beneficiary.released = beneficiary.released.add(refund);

        Revoked(_beneficiary);
    }

     
    function destroyBeneficiary(address _beneficiary) public onlyOwner {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];

        uint256 balance = beneficiary.vested.sub(beneficiary.released);

        token.transfer(owner, balance);

        totalReleased = totalReleased.add(balance);

        beneficiary.isBeneficiary = false;
        beneficiary.released = beneficiary.released.add(balance);

        BeneficiaryDestroyed(_beneficiary);
    }

     
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return vestedAmount(_beneficiary).sub(beneficiaries[_beneficiary].released);
    }

     
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        Beneficiary storage beneficiary = beneficiaries[_beneficiary];
        uint256 totalBalance = beneficiary.vested;

        if (now < beneficiary.cliff) {
            return 0;
        } else if (now >= beneficiary.start.add(beneficiary.duration) || beneficiary.revoked) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(beneficiary.start)).div(beneficiary.duration);
        }
    }

     
    function flushEth() public onlyOwner {
        owner.transfer(this.balance);
    }

     
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
        selfdestruct(owner);
    }
}