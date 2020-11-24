 

pragma solidity ^0.4.24;


contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract KeralaDonationContract is Ownable {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    uint public amountRaised;
    bool donationClosed = false;

    mapping (address => uint256) public balanceOf;
     
    mapping (address => uint256) public balance;
    event FundTransfer(address backer, uint amount, bool isContribution);
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    constructor() public {
        name = 'Kerala Flood Donation Token';
        symbol = 'KFDT';
        decimals = 0;
        totalSupply = 1000000;

        balanceOf[owner] = totalSupply;
        amountRaised = 0;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] == 0);
        require(_value == 1);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public onlyOwner returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function disableDonation() public onlyOwner returns(bool success) {
      donationClosed = true;
      return true;
    }


     
    function enableDonation() public onlyOwner returns(bool success) {
      donationClosed = false;
      return true;
    }

     
    function checkMyDonation() public view returns(uint) {
      return balance[msg.sender];
    }

     
    function isBacker() public view returns(bool) {
      if (balanceOf[msg.sender] > 0) {
        return true;
      }
      return false;
    }

     
    function () payable public {
        require(!donationClosed);
        uint amount = msg.value;
        amountRaised += amount;
        balance[msg.sender] += amount;
        transfer(msg.sender, 1);
        owner.transfer(msg.value);
    }
}