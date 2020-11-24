 

pragma solidity 0.5.10;

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
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
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 
contract EtherPayment is Ownable, ReentrancyGuard {

    uint8 private _recipientLimit = 7;

    address payable public wallet;

     
    constructor(address _owner, address payable _wallet) public Ownable(_owner) {
        changeWallet(_wallet);
    }

     
    function multiTransfer(address payable[] memory _recipients, uint256[] memory _etherAmounts) public payable nonReentrant {
        require(_recipients.length == _etherAmounts.length);
        require(_recipients.length <= _recipientLimit);

         
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].send(_etherAmounts[i]);
        }

        if (address(this).balance > 0) {
            wallet.send(address(this).balance);
        }
    }

     
    function changeWallet(address payable _newWallet) public onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

}