 

pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Whitelisting is Ownable {
    mapping(address => bool) public isInvestorApproved;
    mapping(address => bool) public isInvestorPaymentApproved;

    event Approved(address indexed investor);
    event Disapproved(address indexed investor);

    event PaymentApproved(address indexed investor);
    event PaymentDisapproved(address indexed investor);


     
    function approveInvestor(address toApprove) public onlyOwner {
        isInvestorApproved[toApprove] = true;
        emit Approved(toApprove);
    }

    function approveInvestorsInBulk(address[] calldata toApprove) external onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorApproved[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

    function disapproveInvestor(address toDisapprove) public onlyOwner {
        delete isInvestorApproved[toDisapprove];
        emit Disapproved(toDisapprove);
    }

    function disapproveInvestorsInBulk(address[] calldata toDisapprove) external onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorApproved[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }

     
    function approveInvestorPayment(address toApprove) public onlyOwner {
        isInvestorPaymentApproved[toApprove] = true;
        emit PaymentApproved(toApprove);
    }

    function approveInvestorsPaymentInBulk(address[] calldata toApprove) external onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorPaymentApproved[toApprove[i]] = true;
            emit PaymentApproved(toApprove[i]);
        }
    }

    function disapproveInvestorapproveInvestorPayment(address toDisapprove) public onlyOwner {
        delete isInvestorPaymentApproved[toDisapprove];
        emit PaymentDisapproved(toDisapprove);
    }

    function disapproveInvestorsPaymentInBulk(address[] calldata toDisapprove) external onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorPaymentApproved[toDisapprove[i]];
            emit PaymentDisapproved(toDisapprove[i]);
        }
    }

}