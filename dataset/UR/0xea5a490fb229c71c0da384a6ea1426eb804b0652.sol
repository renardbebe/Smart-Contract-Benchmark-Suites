 

pragma solidity ^0.4.24;

 


 
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
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract Zer0netDbInterface {
     
    function getAddress(bytes32 _key) external view returns (address);
    function getBool(bytes32 _key)    external view returns (bool);
    function getBytes(bytes32 _key)   external view returns (bytes);
    function getInt(bytes32 _key)     external view returns (int);
    function getString(bytes32 _key)  external view returns (string);
    function getUint(bytes32 _key)    external view returns (uint);

     
    function setAddress(bytes32 _key, address _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setString(bytes32 _key, string _value) external;
    function setUint(bytes32 _key, uint _value) external;

     
    function deleteAddress(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);
    }
}


 
contract Zitetags is Owned {
    using SafeMath for uint;

     
    uint public version;

     
    Zer0netDbInterface public zer0netDb;

     
    event ZitetagUpdate(
        bytes32 indexed zitetagId, 
        string zitetag, 
        string info
    );

     
    constructor() public {
         
        version = now;

         
         
        zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);
    }

     
    modifier onlyAuthBy0Admin() {
         
        require(zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.zitetags'))) == true);

        _;       
    }

     
    function getInfo(string _zitetag) external view returns (string) {
         
        bytes32 hash = keccak256(abi.encodePacked('zitetag.', _zitetag));
        
         
        string memory info = zer0netDb.getString(hash);

         
        return (info);
    }

     
    function setInfo(
        string _zitetag, 
        string _info
    ) onlyAuthBy0Admin external returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked('zitetag.', _zitetag));
        
         
        zer0netDb.setString(hash, _info);

         
        emit ZitetagUpdate(hash, _zitetag, _info);

         
        return true;
    }

     
    function () public payable {
         
        revert('Oops! Direct payments are NOT permitted here.');
    }

     
    function transferAnyERC20Token(
        address tokenAddress, uint tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}