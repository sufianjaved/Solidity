pragma solidity ^0.6.0;
import "./IERC20.sol";
import "./SafeMath.sol";

contract BCCCappedToken is IERC20{ //ERC20
    //Extending Uint256 with SafeMath Library.
    using SafeMath for uint256;
    
    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //Owner Spender allowance
    mapping (address => mapping (address => uint256)) private _allowances;

    //the amount of tokens in existence
    uint256 private _totalSupply;

    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint8 public decimals;
   
    uint private _cappedLimit; 
   
    constructor () public {
        name = "Sufian Token";
        symbol = "SUFI";
        decimals = 2;
        owner = msg.sender;
        //1 million tokens to be generated
        //1 * (10**18)  = 1;
        
        _totalSupply = 100000000 * (10 ** uint256(decimals)); //Initial tokens supplied
        _cappedLimit = 200000000 * (10 ** uint256(decimals)); //total supply cap
		
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual  override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] > amount, "Transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender].sub(amount);
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override  returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "Approve from the zero address"); //checking tokenOwner address is not a null address
        require(spender != address(0), "Approve to the zero address"); //checking spender address is not a null address
		require(balanceOf(tokenOwner) >= amount, "Insufficient balance");
		
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender];
        require(_allowance > amount, "Transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance.sub(amount);
        
        //--- start transfer execution -- 
        
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner].sub(amount); 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }

    function mint(address minter, uint256 amount) public onlyOwner returns(uint256){
		require(minter != address(0), "Invalid address");
		require(amount > 0,"Minted amount should be greater than 0");
        require((_balances[owner].add(amount)) <= _cappedLimit, "Total Supply of the token cannot exceed from Capped Limit");
		
		_totalSupply = _totalSupply.add(amount);
    }
   
    modifier onlyOwner(){
        require(msg.sender == owner, "Permission Denied: Only owner can execute this feature");
        _;
    }
}