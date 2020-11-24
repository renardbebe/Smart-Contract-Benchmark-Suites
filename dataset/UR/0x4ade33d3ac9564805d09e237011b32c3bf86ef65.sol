 

pragma solidity ^0.4.13;

 
contract KittenCoin {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address owner, address spender) public constant returns (uint256) {}
}

contract KittenSale {
    KittenCoin public _kittenContract;
    address public _kittenOwner;
    uint256 public totalContributions;
    uint256 public kittensSold;
    uint256 public kittensRemainingForSale;
    
    function KittenSale () {
        address c = 0xac2BD14654BBf22F9d8f20c7b3a70e376d3436B4;  
        _kittenContract = KittenCoin(c); 
        _kittenOwner = msg.sender;
        totalContributions = 0;
        kittensSold = 0;
        kittensRemainingForSale = 0;  
    }
    
      
    function () payable {
        require(msg.value > 0);
        uint256 contribution = msg.value;
        if (msg.value >= 100 finney) {
            if (msg.value >= 1 ether) {
                contribution /= 6666;
            } else {
                contribution /= 8333;
            }
        } else {
            contribution /= 10000;
        }
        require(kittensRemainingForSale >= contribution);
        totalContributions += msg.value;
        kittensSold += contribution;
        _kittenContract.transferFrom(_kittenOwner, msg.sender, contribution);
        _kittenOwner.transfer(msg.value);
        updateKittensRemainingForSale();
    }
    
    function updateKittensRemainingForSale () {
        kittensRemainingForSale = _kittenContract.allowance(_kittenOwner, this);
    }
    
}