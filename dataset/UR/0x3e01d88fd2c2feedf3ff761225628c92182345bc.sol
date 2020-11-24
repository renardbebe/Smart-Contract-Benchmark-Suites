 

pragma solidity ^0.4.20;

 

 

contract Etherich {
    address public owner;
    
    uint constant public PARTICIPATION_FEE = 0.1 ether;
    uint[] public REFERRAL_RATE = [40, 25, 15, 10, 5];

    mapping (address => address) members;
    mapping (string => address) referralCodes;
    uint public memberCount;

    event HasNewMember(uint memberCount);
    
    function Etherich() public {
        owner = msg.sender;
        members[owner] = 1;

        string memory alphabetHash = hash(owner);
        referralCodes[alphabetHash] = owner;

        memberCount = 1;
    }
    
    function participate(string referral) public payable {
        require(referralCodes[referral] != 0);
        require(members[msg.sender] == 0);
        require(msg.value == PARTICIPATION_FEE);
        
        address referrer = referralCodes[referral];
        members[msg.sender] = referrer;
        string memory alphabetHash = hash(msg.sender);
        referralCodes[alphabetHash] = msg.sender;
        
        for (uint16 i = 0; i<5; i++) {
            if (referrer == 1) {
                break;
            }
            
            uint256 amount = SafeMath.div(SafeMath.mul(msg.value, REFERRAL_RATE[i]), 100);
            referrer.transfer(amount);
            referrer = members[referrer];
        }

        memberCount++;
        HasNewMember(memberCount);
    }
    
    function isMember(address a) public view returns(bool) {
        return !(members[a] == 0);
    }
    
    function doesReferralCodeValid(string code) public view returns(bool) {
        return !(referralCodes[code] == 0);
    }
    
    function referralCodeFromAddress(address a) public view returns (string) {
        if (this.isMember(a)) {
            return hash(a);
        } else {
            return "";
        }
    }

    function getReferralRates() public view returns (uint[]) {
        return REFERRAL_RATE;
    }
    
    function payout(address receiver, uint amount) public restricted {
        if (amount > this.balance) {
            receiver.transfer(this.balance);
        } else {
            receiver.transfer(amount);
        }
    }

    function changeOwner(address newOwner) public restricted {
        owner = newOwner;
    }
    
    function hash(address a) private pure returns (string) {
        bytes32 sha3Hash = keccak256(bytes20(a));
        return bytes32ToAlphabetString(sha3Hash);
    }
    
    function bytes32ToAlphabetString(bytes32 x) private pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint8 charCount = 0;

        for (uint j = 0; j < 32; j++) {
            uint8 value = uint8(x[j]) % 24;
            byte char = byte(65 + value);
            bytesString[charCount] = char;
            charCount++;
        }

        return string(bytesString);
    } 
    
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }
}

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