 

pragma solidity ^0.4.25;

interface Snip3DInterface  {
    function() payable external;
   function offerAsSacrifice(address MN)
        external
        payable
        ;
         function withdraw()
        external
        ;
        function myEarnings()
        external
        view
       
        returns(uint256);
        function tryFinalizeStage()
        external;
    function sendInSoldier(address masternode, uint256 amount) external payable;
    function fetchdivs(address toupdate) external;
    function shootSemiRandom() external;
    function vaultToWallet(address toPay) external;
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}
 
 
 
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
 
contract Slaughter3D is  Owned {
    using SafeMath for uint;
    Snip3DInterface constant Snip3Dcontract_ = Snip3DInterface(0x31cF8B6E8bB6cB16F23889F902be86775bB1d0B3);
    uint256 public toSnipe;
    function harvestableBalance()
        view
        public
        returns(uint256)
    {
        uint256 tosend = address(this).balance.sub(toSnipe);
        return ( tosend)  ;
    }
    function unfetchedVault()
        view
        public
        returns(uint256)
    {
        return ( Snip3Dcontract_.myEarnings())  ;
    }
    function sacUp ()  public payable {
       
        toSnipe = toSnipe.add(msg.value);
    }
    function sacUpto (address masternode)  public  {
       require(toSnipe> 0.1 ether);
        toSnipe = toSnipe.sub(0.1 ether);
        Snip3Dcontract_.sendInSoldier.value(0.1 ether)(masternode , 1);
    }
    function fetchvault ()  public {
      
        Snip3Dcontract_.vaultToWallet(address(this));
    }
    function fetchBalance () onlyOwner public {
      uint256 tosend = address(this).balance.sub(toSnipe);
        msg.sender.transfer(tosend);
    }
    function () external payable{}  
}