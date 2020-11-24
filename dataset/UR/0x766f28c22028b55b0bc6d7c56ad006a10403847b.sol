 

pragma solidity ^0.4.18;




 
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






contract BuckySalary is Ownable {

    address[] public staff;
    mapping(address => uint) public eth;

    
    function BuckySalary() public {

    }


    function getTotal() internal view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < staff.length; i++) {
            total += eth[staff[i]];    
        }

        return total;
    }

    event Transfer(address a, uint v);

    function () public payable {
        uint total = getTotal();
        require(msg.value >= total);

        for (uint i = 0; i < staff.length; i++) {
            
            address s = staff[i];
            uint value = eth[s];
            if (value > 0) {
                s.transfer(value);
                Transfer(s, value);
            }
        }

        if (msg.value > total) {
            msg.sender.transfer(msg.value - total);
        }
    }


    function setETH(address addr, uint value) public onlyOwner {
        if (eth[addr] == 0) {
            staff.push(addr);
        }

        eth[addr] = value;
    }

    function setMultiETH(address[] addr, uint[] value) public onlyOwner {
        require(addr.length == value.length);
        for (uint i = 0; i < addr.length; i++) {
            setETH(addr[i], value[i]);
        }
    }

}