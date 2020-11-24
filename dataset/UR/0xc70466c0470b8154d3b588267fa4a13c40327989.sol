 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.11;



contract MBPRK01 is ERC20, ERC20Detailed {

  string public NAME = "Precatorio MB SP 01";
  string public SYMBOL = "MBPRK01";
  uint8 public DECIMALS = 0;
  uint public INITIAL_SUPPLY = 12000;

  string public plataformaDeNegociacao;
  string public guardaDoPrecatorio;
  string public originador;
  string public valorOriginalDoPrecatorio;
  string public valorDaEmissaoMB;
  string public formaDeAtualizacao;
  string public responsavelPeloPagamento;
  string public tipo;
  string public dataEstimadaNaoGarantidaDePagamento;
  string public numeroProcesso;
  string public tribunal;
  string public urlDocumentosAcessorios;
  string public urlDetalhesFinanceiros;

  address public owner;

  event OwnerChanged(address oldOwner, address newOwner);

  modifier onlyOwner() {
    require(owner == msg.sender, "Restricted for owner");
    _;
  }

  constructor() ERC20Detailed(NAME, SYMBOL, DECIMALS) public {
    owner = msg.sender;
    _mint(owner, INITIAL_SUPPLY);

    plataformaDeNegociacao = "MERCADO BITCOIN SERVIÇOS DIGITAIS LTDA CNPJ 18.213.434/0001-35";
    guardaDoPrecatorio = "MJFH 2312004 CAPITAL LTDA CNPJ: 33.591.287/0001-20";
    originador = "HURST CAPITAL LTDA CNPJ: 29.765.165/0001-36";
    valorOriginalDoPrecatorio = "vide processo";
    valorDaEmissaoMB = "R$1.200.000,00";
    formaDeAtualizacao = "vide processo";
    responsavelPeloPagamento = "Estado de SP";
    tipo = "Alimentar";
    dataEstimadaNaoGarantidaDePagamento = "2021";
    numeroProcesso = "0407495-81.1994.8.26.0053";
    tribunal = "Tribunal de Justiça do Estado de São Paulo";
    urlDocumentosAcessorios = "registro.mercadobitcoin.com.br/precatorio/mbprk01";
    urlDetalhesFinanceiros = "https://www.mercadobitcoin.com.br/precatorio/rsc/files/mercado-precatorio.pdf";
  }

  function setPlataformaDeNegociacao (string memory v) public onlyOwner() {
    plataformaDeNegociacao = v;
  }

  function setGuardaDoPrecatorio (string memory v) public  onlyOwner() {
    guardaDoPrecatorio = v;
  }

  function setOriginador (string memory v) public  onlyOwner() {
    originador = v;
  }

  function setValorOriginalDoPrecatorio (string memory v) public  onlyOwner() {
    valorOriginalDoPrecatorio = v;
  }

  function setValorDaEmissaoMB (string memory v) public  onlyOwner() {
    valorDaEmissaoMB = v;
  }

  function setFormaDeAtualizacao (string memory v) public  onlyOwner() {
    formaDeAtualizacao = v;
  }

  function setResponsavelPeloPagamento (string memory v) public  onlyOwner() {
    responsavelPeloPagamento = v;
  }

  function setTipo (string memory v) public onlyOwner() {
    tipo = v;
  }

  function setDataEstimadaNaoGarantidaDePagamento (string memory v) public onlyOwner() {
    dataEstimadaNaoGarantidaDePagamento = v;
  }

  function setNumeroProcesso (string memory v) public  onlyOwner() {
    numeroProcesso = v;
  }

  function setTribunal (string memory v) public  onlyOwner() {
    tribunal = v;
  }

  function setUrlDocumentosAcessorios (string memory v) public onlyOwner() {
    urlDocumentosAcessorios = v;
  }

  function setUrlDetalhesFinanceiros (string memory v) public onlyOwner() {
    urlDetalhesFinanceiros = v;
  }

  function changeOwner(address newOwner) public  onlyOwner() {
    address oldOwner = owner;
    owner = newOwner;

    emit OwnerChanged(oldOwner, owner);
  }
}