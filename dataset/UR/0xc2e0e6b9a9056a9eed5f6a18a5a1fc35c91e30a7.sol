 

 

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

 

pragma solidity ^0.5.4;



 
contract RepAllocation is Ownable {


        
    mapping(address   =>   uint256) public reputationAllocations;
    bool public isFreeze;

    event BeneficiaryAddressAdded(address indexed _beneficiary, uint256 indexed _amount);

     
    function addBeneficiary(address _beneficiary, uint256 _amount) public onlyOwner {
        require(!isFreeze, "can add beneficiary only if not disable");

        if (reputationAllocations[_beneficiary] == 0) {
            reputationAllocations[_beneficiary] = _amount;
            emit BeneficiaryAddressAdded(_beneficiary, _amount);
        }
    }

     
    function addBeneficiaries(address[] memory _beneficiaries, uint256[] memory _amounts) public onlyOwner {
        require(_beneficiaries.length == _amounts.length);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i], _amounts[i]);
        }
    }

     
    function freeze() public onlyOwner {
        isFreeze = true;
    }

     
    function balanceOf(address _beneficiary) public view returns(uint256) {
        return reputationAllocations[_beneficiary];
    }

}