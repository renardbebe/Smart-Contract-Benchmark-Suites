 

pragma solidity ^0.4.23;

 

contract Ownerable {
     
     
    modifier onlyOwner { require(msg.sender == owner); _; }

    address public owner;

    constructor() public { owner = msg.sender;}

     
     
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

 

contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

 

contract ATXICOToken {
    function atxBuy(address _from, uint256 _amount) public returns(bool);
}

 

contract ATX {
    function blacklistAccount(address tokenOwner) public returns (bool);
    function unBlacklistAccount(address tokenOwner) public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function changeController(address _newController) public;
}

 

contract ATXController is TokenController, Ownerable {

    address public atxContract;
    mapping (address => bool) public icoTokens;

    event Debug(address indexed _from, address indexed _to, uint256 indexed _amount, uint ord);

    constructor (address _atxContract) public {
        atxContract = _atxContract;
    }

    function addICOToken(address _icoToken) public onlyOwner {
        icoTokens[_icoToken] = true;
    }
    function delICOToken(address _icoToken) public onlyOwner {
        icoTokens[_icoToken] = false;
    }

    function proxyPayment(address _owner) public payable returns(bool) {
        return false;
    }

    function onTransfer(address _from, address _to, uint256 _amount) public returns(bool) {
        require(atxContract == msg.sender);
        require(_to != 0x0);

         
        bool result = true;

        if(icoTokens[_to] == true) {
            result = ATXICOToken(_to).atxBuy(_from, _amount);
        }
        return result;
    }

    function onApprove(address _owner, address _spender, uint _amount) public returns(bool) {
        return true;
    }

     
     
    function blacklist(address tokenOwner) public onlyOwner returns (bool) {
        return ATX(atxContract).blacklistAccount(tokenOwner);
    }

    function unBlacklist(address tokenOwner) public onlyOwner returns (bool) {
        return ATX(atxContract).unBlacklistAccount(tokenOwner);
    }

    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        ATX(atxContract).enableTransfers(_transfersEnabled);
    }

    function changeController(address _newController) public onlyOwner {
        ATX(atxContract).changeController(_newController);
    }

    function changeATXTokenAddr(address _newTokenAddr) public onlyOwner {
        atxContract = _newTokenAddr;
    }

    function ownerMethod() public onlyOwner returns(bool) {
      return true;
    }
}