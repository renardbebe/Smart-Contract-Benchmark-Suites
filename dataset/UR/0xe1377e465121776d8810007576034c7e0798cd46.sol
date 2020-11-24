 

pragma solidity 0.4.19;


contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}




contract ERC20TransferInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) constant public returns (uint256);
}




contract MultiSigWallet is Ownable {

    event AddressAuthorised(address indexed addr);
    event AddressUnauthorised(address indexed addr);
    event TransferOfEtherRequested(address indexed by, address indexed to, uint256 valueInWei);
    event EthTransactionConfirmed(address indexed by);
    event EthTransactionRejected(address indexed by);
    event TransferOfErc20Requested(address indexed by, address indexed to, address indexed token, uint256 value);
    event Erc20TransactionConfirmed(address indexed by);
    event Erc20TransactionRejected(address indexed by);

     
    struct EthTransactionRequest {
        address _from;
        address _to;
        uint256 _valueInWei;
    }

     
    struct Erc20TransactionRequest {
        address _from;
        address _to;
        address _token;
        uint256 _value;
    }

    EthTransactionRequest public latestEthTxRequest;
    Erc20TransactionRequest public latestErc20TxRequest;

    mapping (address => bool) public isAuthorised;


     
    function MultiSigWallet() public {
 
        isAuthorised[0xF748D2322ADfE0E9f9b262Df6A2aD6CBF79A541A] = true;  
        isAuthorised[0x4BbBbDd42c7aab36BeA6A70a0cB35d6C20Be474E] = true;  
        isAuthorised[0x2E661Be8C26925DDAFc25EEe3971efb8754E6D90] = true;  
        isAuthorised[0x1ee9b4b8c9cA6637eF5eeCEE62C9e56072165AAF] = true;  

    }

    modifier onlyAuthorisedAddresses {
        require(isAuthorised[msg.sender] = true);
        _;
    }

    modifier validEthConfirmation {
        require(msg.sender != latestEthTxRequest._from);
        _;
    }

    modifier validErc20Confirmation {
        require(msg.sender != latestErc20TxRequest._from);
        _;
    }

     
    function() public payable { }

     
    function authoriseAddress(address _addr) public onlyOwner {
        require(_addr != 0x0 && !isAuthorised[_addr]);
        isAuthorised[_addr] = true;
        AddressAuthorised(_addr);
    }

     
    function unauthoriseAddress(address _addr) public onlyOwner {
        require(isAuthorised[_addr] && _addr != owner);
        isAuthorised[_addr] = false;
        AddressUnauthorised(_addr);
    }

     
    function requestTransferOfETH(address _to, uint256 _valueInWei) public onlyAuthorisedAddresses {
        require(_to != 0x0 && _valueInWei > 0);
        latestEthTxRequest = EthTransactionRequest(msg.sender, _to, _valueInWei);
        TransferOfEtherRequested(msg.sender, _to, _valueInWei);
    }

     
    function requestErc20Transfer(address _token, address _to, uint256 _value) public onlyAuthorisedAddresses {
        ERC20TransferInterface token = ERC20TransferInterface(_token);
        require(_to != 0x0 && _value > 0 && token.balanceOf(address(this)) >= _value);
        latestErc20TxRequest = Erc20TransactionRequest(msg.sender, _to, _token, _value);
        TransferOfErc20Requested(msg.sender, _to, _token, _value);
    }

     
    function confirmEthTransactionRequest() public onlyAuthorisedAddresses validEthConfirmation  {
        require(isAuthorised[latestEthTxRequest._from] && latestEthTxRequest._to != 0x0 && latestEthTxRequest._valueInWei > 0);
        latestEthTxRequest._to.transfer(latestEthTxRequest._valueInWei);
        latestEthTxRequest = EthTransactionRequest(0x0, 0x0, 0);
        EthTransactionConfirmed(msg.sender);
    }

     
    function confirmErc20TransactionRequest() public onlyAuthorisedAddresses validErc20Confirmation {
        require(isAuthorised[latestErc20TxRequest._from] && latestErc20TxRequest._to != 0x0 && latestErc20TxRequest._value != 0 && latestErc20TxRequest._token != 0x0);
        ERC20TransferInterface token = ERC20TransferInterface(latestErc20TxRequest._token);
        token.transfer(latestErc20TxRequest._to,latestErc20TxRequest._value);
        latestErc20TxRequest = Erc20TransactionRequest(0x0, 0x0, 0x0, 0);
        Erc20TransactionConfirmed(msg.sender);
    }

     
    function rejectEthTransactionRequest() public onlyAuthorisedAddresses {
        latestEthTxRequest = EthTransactionRequest(0x0, 0x0, 0);
        EthTransactionRejected(msg.sender);
    }

     
    function rejectErx20TransactionRequest() public onlyAuthorisedAddresses {
        latestErc20TxRequest = Erc20TransactionRequest(0x0, 0x0, 0x0, 0);
        Erc20TransactionRejected(msg.sender);
    }

     
    function viewLatestEthTransactionRequest() public view returns(address from, address to, uint256 valueInWei) {
        return (latestEthTxRequest._from, latestEthTxRequest._to, latestEthTxRequest._valueInWei);
    }

     
    function viewLatestErc20TransactionRequest() public view returns(address from, address to, address token, uint256 value) {
        return(latestErc20TxRequest._from, latestErc20TxRequest._to, latestErc20TxRequest._token, latestErc20TxRequest._value);
    }
}