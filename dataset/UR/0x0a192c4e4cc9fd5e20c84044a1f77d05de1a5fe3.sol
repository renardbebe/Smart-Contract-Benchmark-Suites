 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}









 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}





 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}





 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}





 
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


contract BNDESRegistry is Ownable() {

     
    enum BlockchainAccountState {AVAILABLE,WAITING_VALIDATION,VALIDATED,INVALIDATED_BY_VALIDATOR,INVALIDATED_BY_CHANGE} 
    BlockchainAccountState blockchainState;  

    address responsibleForSettlement;
    address responsibleForRegistryValidation;
    address responsibleForDisbursement;
    address redemptionAddress;
    address tokenAddress;

     
    struct LegalEntityInfo {
        uint64 cnpj;  
        uint64 idFinancialSupportAgreement;  
        uint32 salic;  
        string idProofHash;  
        BlockchainAccountState state;
    } 

     
    mapping(address => LegalEntityInfo) public legalEntitiesInfo;

     
    mapping(uint64 => mapping(uint64 => address)) cnpjFSAddr; 


     
    mapping(address => bool) public legalEntitiesChangeAccount;


    event AccountRegistration(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string idProofHash);
    event AccountChange(address oldAddr, address newAddr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string idProofHash);
    event AccountValidation(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic);
    event AccountInvalidation(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic);

     
    modifier onlyTokenAddress() {
        require(isTokenAddress());
        _;
    }

    constructor () public {
        responsibleForSettlement = msg.sender;
        responsibleForRegistryValidation = msg.sender;
        responsibleForDisbursement = msg.sender;
        redemptionAddress = msg.sender;
    }


    
    function registryLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, 
        address addr, string memory idProofHash) onlyTokenAddress public { 

         
        require (isAvailableAccount(addr), "Endereço não pode ter sido cadastrado anteriormente");

        require (isValidHash(idProofHash), "O hash da declaração é inválido");

        legalEntitiesInfo[addr] = LegalEntityInfo(cnpj, idFinancialSupportAgreement, salic, idProofHash, BlockchainAccountState.WAITING_VALIDATION);
        
         
        if (idFinancialSupportAgreement > 0) {
            address account = getBlockchainAccount(cnpj,idFinancialSupportAgreement);
            require (isAvailableAccount(account), "Cliente já está associado a outro endereço. Use a função Troca.");
        }
        else {
            address account = getBlockchainAccount(cnpj,0);
            require (isAvailableAccount(account), "Fornecedor já está associado a outro endereço. Use a função Troca.");
        }
        
        cnpjFSAddr[cnpj][idFinancialSupportAgreement] = addr;

        emit AccountRegistration(addr, cnpj, idFinancialSupportAgreement, salic, idProofHash);
    }

    
    function changeAccountLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, 
        address newAddr, string memory idProofHash) onlyTokenAddress public {

        address oldAddr = getBlockchainAccount(cnpj, idFinancialSupportAgreement);
    
         
        require(!isReservedAccount(oldAddr), "Não pode trocar endereço de conta reservada");

        require(!isAvailableAccount(oldAddr), "Tem que haver um endereço associado a esse cnpj/subcrédito");

        require(isAvailableAccount(newAddr), "Novo endereço não está disponível");

        require (isChangeAccountEnabled(oldAddr), "A conta atual não está habilitada para troca");

        require (isValidHash(idProofHash), "O hash da declaração é inválido");        

        require(legalEntitiesInfo[oldAddr].cnpj==cnpj 
                    && legalEntitiesInfo[oldAddr].idFinancialSupportAgreement ==idFinancialSupportAgreement, 
                    "Dados inconsistentes de cnpj ou subcrédito");

         
        legalEntitiesInfo[newAddr] = LegalEntityInfo(cnpj, idFinancialSupportAgreement, salic, idProofHash, BlockchainAccountState.WAITING_VALIDATION);

         
        legalEntitiesInfo[oldAddr].state = BlockchainAccountState.INVALIDATED_BY_CHANGE;

         
        cnpjFSAddr[cnpj][idFinancialSupportAgreement] = newAddr;

        emit AccountChange(oldAddr, newAddr, cnpj, idFinancialSupportAgreement, salic, idProofHash); 

    }

    
    function validateRegistryLegalEntity(address addr, string memory idProofHash) public {

        require(isResponsibleForRegistryValidation(msg.sender), "Somente o responsável pela validação pode validar contas");

        require(legalEntitiesInfo[addr].state == BlockchainAccountState.WAITING_VALIDATION, "A conta precisa estar no estado Aguardando Validação");

        require(keccak256(abi.encodePacked(legalEntitiesInfo[addr].idProofHash)) == keccak256(abi.encodePacked(idProofHash)), "O hash recebido é diferente do esperado");

        legalEntitiesInfo[addr].state = BlockchainAccountState.VALIDATED;

        emit AccountValidation(addr, legalEntitiesInfo[addr].cnpj, 
            legalEntitiesInfo[addr].idFinancialSupportAgreement,
            legalEntitiesInfo[addr].salic);
    }

    
    function invalidateRegistryLegalEntity(address addr) public {

        require(isResponsibleForRegistryValidation(msg.sender), "Somente o responsável pela validação pode invalidar contas");

        require(!isReservedAccount(addr), "Não é possível invalidar conta reservada");

        legalEntitiesInfo[addr].state = BlockchainAccountState.INVALIDATED_BY_VALIDATOR;
        
        emit AccountInvalidation(addr, legalEntitiesInfo[addr].cnpj, 
            legalEntitiesInfo[addr].idFinancialSupportAgreement,
            legalEntitiesInfo[addr].salic);
    }


    
    function setResponsibleForSettlement(address rs) onlyOwner public {
        responsibleForSettlement = rs;
    }

    
    function setResponsibleForRegistryValidation(address rs) onlyOwner public {
        responsibleForRegistryValidation = rs;
    }

    
    function setResponsibleForDisbursement(address rs) onlyOwner public {
        responsibleForDisbursement = rs;
    }

    
    function setRedemptionAddress(address rs) onlyOwner public {
        redemptionAddress = rs;
    }

    
    function setTokenAddress(address rs) onlyOwner public {
        tokenAddress = rs;
    }

    
    function enableChangeAccount (address rs) public {
        require(isResponsibleForRegistryValidation(msg.sender), "Somente o responsável pela validação pode habilitar a troca de conta");
        legalEntitiesChangeAccount[rs] = true;
    }

    function isChangeAccountEnabled (address rs) view public returns (bool) {
        return legalEntitiesChangeAccount[rs] == true;
    }    

    function isTokenAddress() public view returns (bool) {
        return tokenAddress == msg.sender;
    } 
    function isResponsibleForSettlement(address addr) view public returns (bool) {
        return (addr == responsibleForSettlement);
    }
    function isResponsibleForRegistryValidation(address addr) view public returns (bool) {
        return (addr == responsibleForRegistryValidation);
    }
    function isResponsibleForDisbursement(address addr) view public returns (bool) {
        return (addr == responsibleForDisbursement);
    }
    function isRedemptionAddress(address addr) view public returns (bool) {
        return (addr == redemptionAddress);
    }

    function isReservedAccount(address addr) view public returns (bool) {

        if (isOwner(addr) || isResponsibleForSettlement(addr) 
                           || isResponsibleForRegistryValidation(addr)
                           || isResponsibleForDisbursement(addr)
                           || isRedemptionAddress(addr) ) {
            return true;
        }
        return false;
    }
    function isOwner(address addr) view public returns (bool) {
        return owner()==addr;
    }

    function isSupplier(address addr) view public returns (bool) {

        if (isReservedAccount(addr))
            return false;

        if (isAvailableAccount(addr))
            return false;

        return legalEntitiesInfo[addr].idFinancialSupportAgreement == 0;
    }

    function isValidatedSupplier (address addr) view public returns (bool) {
        return isSupplier(addr) && (legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED);
    }

    function isClient (address addr) view public returns (bool) {
        if (isReservedAccount(addr)) {
            return false;
        }
        return legalEntitiesInfo[addr].idFinancialSupportAgreement != 0;
    }

    function isValidatedClient (address addr) view public returns (bool) {
        return isClient(addr) && (legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED);
    }

    function isAvailableAccount(address addr) view public returns (bool) {
        if ( isReservedAccount(addr) ) {
            return false;
        } 
        return legalEntitiesInfo[addr].state == BlockchainAccountState.AVAILABLE;
    }

    function isWaitingValidationAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.WAITING_VALIDATION;
    }

    function isValidatedAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED;
    }

    function isInvalidatedByValidatorAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.INVALIDATED_BY_VALIDATOR;
    }

    function isInvalidatedByChangeAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.INVALIDATED_BY_CHANGE;
    }

    function getResponsibleForSettlement() view public returns (address) {
        return responsibleForSettlement;
    }
    function getResponsibleForRegistryValidation() view public returns (address) {
        return responsibleForRegistryValidation;
    }
    function getResponsibleForDisbursement() view public returns (address) {
        return responsibleForDisbursement;
    }
    function getRedemptionAddress() view public returns (address) {
        return redemptionAddress;
    }
    function getCNPJ(address addr) view public returns (uint64) {
        return legalEntitiesInfo[addr].cnpj;
    }

    function getIdLegalFinancialAgreement(address addr) view public returns (uint64) {
        return legalEntitiesInfo[addr].idFinancialSupportAgreement;
    }

    function getLegalEntityInfo (address addr) view public returns (uint64, uint64, uint32, string memory, uint, address) {
        return (legalEntitiesInfo[addr].cnpj, legalEntitiesInfo[addr].idFinancialSupportAgreement, 
             legalEntitiesInfo[addr].salic, legalEntitiesInfo[addr].idProofHash, (uint) (legalEntitiesInfo[addr].state),
             addr);
    }

    function getBlockchainAccount(uint64 cnpj, uint64 idFinancialSupportAgreement) view public returns (address) {
        return cnpjFSAddr[cnpj][idFinancialSupportAgreement];
    }

    function getLegalEntityInfoByCNPJ (uint64 cnpj, uint64 idFinancialSupportAgreement) 
        view public returns (uint64, uint64, uint32, string memory, uint, address) {
        
        address addr = getBlockchainAccount(cnpj,idFinancialSupportAgreement);
        return getLegalEntityInfo (addr);
    }

    function getAccountState(address addr) view public returns (int) {

        if ( isReservedAccount(addr) ) {
            return 100;
        } 
        else {
            return ((int) (legalEntitiesInfo[addr].state));
        }

    }


  function isValidHash(string memory str) pure public returns (bool)  {

    bytes memory b = bytes(str);
    if(b.length != 64) return false;

    for (uint i=0; i<64; i++) {
        if (b[i] < "0") return false;
        if (b[i] > "9" && b[i] <"a") return false;
        if (b[i] > "f") return false;
    }
        
    return true;
 }


}


contract BNDESToken is ERC20Pausable, ERC20Detailed("BNDESToken", "BND", 2) {

    uint private version = 20190517;

    BNDESRegistry registry;

    event BNDESTokenDisbursement(uint64 cnpj, uint64 idFinancialSupportAgreement, uint256 value);
    event BNDESTokenTransfer(uint64 fromCnpj, uint64 fromIdFinancialSupportAgreement, uint64 toCnpj, uint256 value);
    event BNDESTokenRedemption(uint64 cnpj, uint256 value);
    event BNDESTokenRedemptionSettlement(string redemptionTransactionHash, string receiptHash);
    event BNDESManualIntervention(string description);

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    constructor (address newRegistryAddr) public {
        registry = BNDESRegistry(newRegistryAddr);
    }


    function getVersion() view public returns (uint) {
        return version;
    }


    
    function transfer (address to, uint256 value) public whenNotPaused returns (bool) {

        address from = msg.sender;

        require(from != to, "Não pode transferir token para si mesmo");

        if (registry.isResponsibleForDisbursement(from)) {

            require(registry.isValidatedClient(to), "O endereço não pertence a um cliente ou não está validada");

            _mint(to, value);

            emit BNDESTokenDisbursement(registry.getCNPJ(to), registry.getIdLegalFinancialAgreement(to), value);

        } else { 

            if (registry.isRedemptionAddress(to)) { 

                require(registry.isValidatedSupplier(from), "A conta do endereço não pertence a um fornecedor ou não está validada");

                _burn(from, value);

                emit BNDESTokenRedemption(registry.getCNPJ(from), value);

            } else {

                 

                require(registry.isValidatedClient(from), "O endereço não pertence a um cliente ou não está validada");
                require(registry.isValidatedSupplier(to), "A conta do endereço não pertence a um fornecedor ou não está validada");

                _transfer(msg.sender, to, value);

                emit BNDESTokenTransfer(registry.getCNPJ(from), registry.getIdLegalFinancialAgreement(from), 
                                registry.getCNPJ(to), value);
  
            }
        }

        return true;
    }

    
    function redeem (uint256 value) public whenNotPaused returns (bool) {
        return transfer(registry.getRedemptionAddress(), value);
    }

    
    function notifyRedemptionSettlement(string memory redemptionTransactionHash, string memory receiptHash) 
        public whenNotPaused {
        require (registry.isResponsibleForSettlement(msg.sender), "A liquidação só não pode ser realizada pelo endereço que submeteu a transação"); 
        require (registry.isValidHash(receiptHash), "O hash do recibo é inválido");
        emit BNDESTokenRedemptionSettlement(redemptionTransactionHash, receiptHash);
    }


    function registryLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string memory idProofHash) 
        public whenNotPaused { 
        registry.registryLegalEntity(cnpj,  idFinancialSupportAgreement, salic, msg.sender, idProofHash);
    }

    
    function changeAccountLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string memory idProofHash) 
        public whenNotPaused {
        
        address oldAddr = registry.getBlockchainAccount(cnpj, idFinancialSupportAgreement);
        address newAddr = msg.sender;
        
        registry.changeAccountLegalEntity(cnpj, idFinancialSupportAgreement, salic, msg.sender, idProofHash);

         
        if (balanceOf(oldAddr) > 0) {
            _transfer(oldAddr, newAddr, balanceOf(oldAddr));
        }

    }

     
    function burn(address from, uint256 value, string memory description) public onlyOwner {
        _burn(from, value);
        emit BNDESManualIntervention(description);        
    }

     
    function mint(address to, uint256 value, string memory description) public onlyOwner {
        _mint(to, value);
        emit BNDESManualIntervention(description);        
    }

    function isOwner() public view returns (bool) {
        return registry.owner() == msg.sender;
    } 

     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(false, "Unsupported method - transferFrom");
    }

     
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(false, "Unsupported method - approve");
    }

     
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        require(false, "Unsupported method - increaseAllowance");
    }

     
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        require(false, "Unsupported method - decreaseAllowance");
    }



}