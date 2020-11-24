 

pragma solidity ^0.5.4;

contract NiftyWallet {
    
      

      

    address masterContractAdd = 0x4CADB4bAd0e2a49CC5D6CE26D8628C8f451dA346;
    uint userAccountID = 0;
    uint walletTxCount = 0;

     

    event Execution(address indexed destinationAddress, uint value, bytes txData);
    event ExecutionFailure(address indexed destinationAddress, uint value, bytes txData);
    event Deposit(address indexed sender, uint value);

     

    function returnUserAccountAddress() public view returns(address) {
        MasterContract m_c_instance = MasterContract(masterContractAdd);
        return (m_c_instance.returnUserControlAddress(userAccountID));
    }
    
    function returnWalletTxCount() public view returns(uint) {
        return(walletTxCount);
    }
    
     
     
    modifier onlyValidSender() {
        MasterContract m_c_instance = MasterContract(masterContractAdd);
        require(m_c_instance.returnIsValidSendingKey(msg.sender) == true);
        _;
      }

      

    function()
        payable
        external
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
        else if (msg.data.length > 0) {
             
            MasterContract m_c_instance = MasterContract(masterContractAdd);
            address loc =  (m_c_instance.returnStaticContractAddress());
                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, loc, 0, calldatasize(), 0, 0)
                    returndatacopy(0, 0, returndatasize())
                    switch result 
                    case 0 {revert(0, returndatasize())} 
                    default {return (0, returndatasize())}
                }
        }
    }
    
      

    function callTx(bytes memory _signedData,
                     address destination,
                     uint value,
                     bytes memory data)
    public onlyValidSender returns (bool) {
        address userSigningAddress = returnUserAccountAddress();
        MasterContract m_c_instance = MasterContract(masterContractAdd);
        bytes32 dataHash = m_c_instance.returnTxMessageToSign(data, destination, value, walletTxCount);
        address recoveredAddress = m_c_instance.recover(dataHash, _signedData);
        if (recoveredAddress==userSigningAddress) {
            if (external_call(destination, value, data.length, data)) {
                emit Execution(destination, value, data);
                walletTxCount = walletTxCount + 1;
            } else {
                emit ExecutionFailure(destination, value, data);
                walletTxCount = walletTxCount +1;
            }
            return(true);
        } else {
            revert();
        }
    }
    
      

     
     
    function external_call(address destination, uint value, uint dataLength, bytes memory data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
                destination,
                value,
                d,
                dataLength,         
                x,
                0                   
            )
        }
        return result;
    }

}

contract MasterContract {
    function returnUserControlAddress(uint account_id) public view returns (address);
    function returnIsValidSendingKey(address sending_key) public view returns (bool);
    function returnStaticContractAddress() public view returns (address);
    function recover(bytes32 hash, bytes memory sig) public pure returns (address);
    function returnTxMessageToSign(bytes memory txData, address des_add, uint value, uint tx_count)
    public view returns(bytes32);
}