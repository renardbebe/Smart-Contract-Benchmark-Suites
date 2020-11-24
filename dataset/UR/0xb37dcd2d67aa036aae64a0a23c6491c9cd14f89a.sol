 

pragma solidity ^0.4.25;


contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



contract Ownable {
    
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract Memberships is Ownable {
    
    using SafeMath for uint256;
    
    
    uint256 private numOfMembers;
    uint256 private maxGramsPerMonth;
    uint256 private monthNo;
    ERC20 public ELYC;
    
    
    constructor() public {
        maxGramsPerMonth = 60;
        ELYC = ERC20(0xFD96F865707ec6e6C0d6AfCe1f6945162d510351); 
    }
    
    
     
    mapping (address => uint256) private memberIdByAddr;
    mapping (uint256 => address) private memberAddrById;
    mapping (address => bool) private addrIsMember;
    mapping (address => mapping (uint256 => uint256)) private memberPurchases;
    mapping (address => bool) private blacklist;
    
    
     
    event MaxGramsPerMonthChanged(uint256 from, uint256 to);
    event MemberBlacklisted(address indexed addr, uint256 indexed id, uint256 block);
    event MemberRemovedFromBlacklist(address indexed addr, uint256 indexed id, uint256 block);
    event NewMemberAdded(address indexed addr, uint256 indexed id, uint256 block);
    event CannabisPurchaseMade(address indexed by, uint256 milligrams, uint256 price, address indexed vendor, uint256 block);
    event PurchaseMade(address indexed by, uint256 _price, address indexed _vendor, uint256 block);
    event MonthNumberIncremented(uint256 block);
    
    
     
     modifier onlyMembers {
         require(
             addressHasMembership(msg.sender)
             && !memberIsBlacklisted(msg.sender)
             );
         _;
     }

    
    
     
     
     
     function getMonthNo() public view returns(uint256) {
         return monthNo;
     }
     
     
    function getNumOfMembers() public view returns(uint256) {
        return numOfMembers;
    }
    
    
     
    function getMaxGramsPerMonth() public view returns(uint256) {
        return maxGramsPerMonth;
    }
    
    
     
    function addressHasMembership(address _addr) public view returns(bool) {
        return addrIsMember[_addr];
    }
    
    
     
    function getMemberIdByAddr(address _addr) public view returns(uint256) {
        return memberIdByAddr[_addr];
    }
    
    
     
    function getMemberAddrById(uint256 _id) public view returns(address) {
        return memberAddrById[_id];
    }
    
    
     
    function memberIsBlacklisted(address _addr) public view returns(bool) {
        return blacklist[_addr];
    }
    
    
     
    function getMilligramsMemberCanBuy(address _addr) public view returns(uint256) {
        uint256 milligrams = memberPurchases[_addr][monthNo];
        if(milligrams >= maxGramsPerMonth.mul(1000)) {
            return 0;
        } else {
            return (maxGramsPerMonth.mul(1000)).sub(milligrams);
        }
    }
    
    

     
    function getMilligramsMemberCanBuy(uint256 _id) public view returns(uint256) {
        uint256 milligrams = memberPurchases[getMemberAddrById(_id)][monthNo];
        if(milligrams >= maxGramsPerMonth.mul(1000)) {
            return 0;
        } else {
            return (maxGramsPerMonth.mul(1000)).sub(milligrams);
        }
    }


    
     
     
      
    function buyCannabis(uint256 _price, uint256 _milligrams, address _vendor) public onlyMembers returns(bool) {
        require(_milligrams > 0 && _price > 0 && _vendor != address(0));
        require(_milligrams <= getMilligramsMemberCanBuy(msg.sender));
        ELYC.transferFrom(msg.sender, _vendor, _price);
        memberPurchases[msg.sender][monthNo] = memberPurchases[msg.sender][monthNo].add(_milligrams);
        emit CannabisPurchaseMade(msg.sender, _milligrams, _price, _vendor, block.number);
        return true;
    }
    
    
    
     
     
     
    function addMember(address _addr) public onlyOwner returns(bool) {
        require(!addrIsMember[_addr]);
        addrIsMember[_addr] = true;
        numOfMembers += 1;
        memberIdByAddr[_addr] = numOfMembers;
        memberAddrById[numOfMembers] = _addr;
        emit NewMemberAdded(_addr, numOfMembers, block.number);
         
         
        owner = msg.sender;
        return true;
    }
    
    
     
    function setMaxGramsPerMonth(uint256 _newMax) public onlyOwner returns(bool) {
        require(_newMax != maxGramsPerMonth && _newMax > 0);
        emit MaxGramsPerMonthChanged(maxGramsPerMonth, _newMax);
        maxGramsPerMonth = _newMax;
        return true;
    }
    
    
     
    function addMemberToBlacklist(address _addr) public onlyOwner returns(bool) {
        emit MemberBlacklisted(_addr, getMemberIdByAddr(_addr), block.number);
        blacklist[_addr] = true;
        return true;
    }
    
    
     
    function addMemberToBlacklist(uint256 _id) public onlyOwner returns(bool) {
        emit MemberBlacklisted(getMemberAddrById(_id), _id, block.number);
        blacklist[getMemberAddrById(_id)] = true;
        return true;
    }
    
    
     
    function removeMemberFromBlacklist(address _addr) public onlyOwner returns(bool) {
        emit MemberRemovedFromBlacklist(_addr, getMemberIdByAddr(_addr), block.number);
        blacklist[_addr] = false;
        return true;
    }
    
    
     
    function removeMemberFromBlacklist(uint256 _id) public onlyOwner returns(bool) {
        emit MemberRemovedFromBlacklist(getMemberAddrById(_id), _id, block.number);
        blacklist[getMemberAddrById(_id)] = false;
        return true;
    }
    
    
     
    function withdrawAnyERC20(address _addressOfToken, address _recipient) public onlyOwner {
        ERC20 token = ERC20(_addressOfToken);
        token.transfer(_recipient, token.balanceOf(address(this)));
    }
    
    
     
    function incrementMonthNo() public onlyOwner {
        emit MonthNumberIncremented(now);
        monthNo = monthNo.add(1);
    }
}