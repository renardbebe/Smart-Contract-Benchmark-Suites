 

pragma solidity ^0.4.19;


 
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


contract ETHERCFeeModifiers is Ownable {

     
    uint256 public commonDiscount;
    uint256 public commonRebate;

     
    mapping (address => uint256) discounts;
     
    mapping (address => uint256) rebates;

    function ETHERCFeeModifiers() public {
        commonDiscount = 0;
        commonRebate = 0;
    }

    function accountFeeModifiers(address _user) public view returns (uint256 feeDiscount, uint256 feeRebate) {
        feeDiscount = discounts[_user] > commonDiscount ? discounts[_user] : commonDiscount;
        feeRebate = rebates[_user] > commonRebate ? rebates[_user] : commonRebate;
    }

    function tradingFeeModifiers(address _maker, address _taker) public view returns (uint256 feeMakeDiscount, uint256 feeTakeDiscount, uint256 feeRebate) {
        feeMakeDiscount = discounts[_maker] > commonDiscount ? discounts[_maker] : commonDiscount;
        feeTakeDiscount = discounts[_taker] > commonDiscount ? discounts[_taker] : commonDiscount;
        feeRebate = rebates[_maker] > commonRebate ? rebates[_maker] : commonRebate;
    }

    function setAccountFeeModifiers(address _user, uint256 _feeDiscount, uint256 _feeRebate) public onlyOwner {
        require(_feeDiscount <= 100 && _feeRebate <= 100);
        discounts[_user] = _feeDiscount;
        rebates[_user] = _feeRebate;
    }

    function changeCommonDiscount(uint256 _commonDiscount) public onlyOwner {
        require(_commonDiscount <=100);
        commonDiscount = _commonDiscount;
    }

    function changeCommonRebate(uint256 _commonRebate) public onlyOwner {
        require(_commonRebate <=100);
        commonRebate = _commonRebate;
    }
}