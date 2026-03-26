# KaTeX 公式语法速查表

## 基本语法

| 类型 | 语法 | 效果 |
|------|------|------|
| 行内公式 | `$x^2$` | $x^2$ |
| 块级公式 | `$$E=mc^2$$` | $$E=mc^2$$ |
| 上标 | `x^2` | $x^2$ |
| 下标 | `x_i` | $x_i$ |
| 组合 | `x^{2n}` | $x^{2n}$ |
| 多字符下标 | `x_{ij}` | $x_{ij}$ |

---

## 分数与根式

| 类型 | 语法 | 效果 |
|------|------|------|
| 分数 | `\frac{a}{b}` | $\frac{a}{b}$ |
| 分数 (行内) | `\tfrac{a}{b}` | $\tfrac{a}{b}$ |
| 平方根 | `\sqrt{x}` | $\sqrt{x}$ |
| n 次方根 | `\sqrt[n]{x}` | $\sqrt[n]{x}$ |
| 堆叠 | `\frac{a+b}{c}` | $\frac{a+b}{c}$ |

---

## 求和、积分、乘积

| 类型 | 语法 | 效果 |
|------|------|------|
| 求和 | `\sum_{i=1}^{n}` | $\sum_{i=1}^{n}$ |
| 积分 | `\int_{a}^{b}` | $\int_{a}^{b}$ |
| 多重积分 | `\iint` `\iiint` | $\iint$ $\iiint$ |
| 乘积 | `\prod_{i=1}^{n}` | $\prod_{i=1}^{n}$ |
| 或 | `\coprod` | $\coprod$ |

---

## 矩阵

### 基本矩阵

```latex
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}
```

效果：$\begin{pmatrix} a & b \\ c & d \end{pmatrix}$

### 其他矩阵括号

| 语法 | 效果 |
|------|------|
| `\begin{bmatrix} ... \end{bmatrix}` | 方括号 |
| `\begin{Bmatrix} ... \end{Bmatrix}` | 大括号 |
| `\begin{vmatrix} ... \end{vmatrix}` | 单竖线行列式 |
| `\begin{Vmatrix} ... \end{Vmatrix}` | 双竖线范数 |

### 省略号

```latex
\begin{pmatrix}
a_{11} & a_{12} & \cdots & a_{1n} \\
a_{21} & a_{22} & \cdots & a_{2n} \\
\vdots & \vdots & \ddots & \vdots \\
a_{m1} & a_{m2} & \cdots & a_{mn}
\end{pmatrix}
```

---

## 希腊字母

| 小写 | 语法 | 大写 | 语法 |
|------|------|------|------|
| $\alpha$ | `\alpha` | $\Alpha$ | `\Alpha` |
| $\beta$ | `\beta` | $\Beta$ | `\Beta` |
| $\gamma$ | `\gamma` | $\Gamma$ | `\Gamma` |
| $\delta$ | `\delta` | $\Delta$ | `\Delta` |
| $\epsilon$ | `\epsilon` | $\Epsilon$ | `\Epsilon` |
| $\theta$ | `\theta` | $\Theta$ | `\Theta` |
| $\lambda$ | `\lambda` | $\Lambda$ | `\Lambda` |
| $\mu$ | `\mu` | $\Mu$ | `\Mu` |
| $\pi$ | `\pi` | $\Pi$ | `\Pi` |
| $\sigma$ | `\sigma` | $\Sigma$ | `\Sigma` |
| $\phi$ | `\phi` | $\Phi$ | `\Phi` |
| $\omega$ | `\omega` | $\Omega$ | `\Omega` |

---

## 关系运算符

| 语法 | 效果 | 语法 | 效果 |
|------|------|------|------|
| `<` | $<$ | `>` | $>$ |
| `\leq` | $\leq$ | `\geq` | $\geq$ |
| `\neq` | $\neq$ | `\approx` | $\approx$ |
| `\equiv` | $\equiv$ | `\sim` | $\sim$ |
| `\propto` | $\propto$ | `\ll` | $\ll$ |
| `\gg` | $\gg$ | `\subset` | $\subset$ |
| `\supset` | $\supset$ | `\subseteq` | $\subseteq$ |
| `\supseteq` | $\supseteq$ | `\in` | $\in$ |
| `\notin` | $\notin$ | `\cup` | $\cup$ |
| `\cap` | $\cap$ | `\emptyset` | $\emptyset$ |

---

## 箭头

| 语法 | 效果 |
|------|------|
| `\to` | $\to$ |
| `\rightarrow` | $\rightarrow$ |
| `\leftarrow` | $\leftarrow$ |
| `\Rightarrow` | $\Rightarrow$ |
| `\Leftarrow` | $\Leftarrow$ |
| `\leftrightarrow` | $\leftrightarrow$ |
| `\Leftrightarrow` | $\Leftrightarrow$ |
| `\uparrow` | $\uparrow$ |
| `\downarrow` | $\downarrow$ |
| `\mapsto` | $\mapsto$ |
| `\longmapsto` | $\longmapsto$ |

---

## 函数

| 语法 | 效果 | 语法 | 效果 |
|------|------|------|------|
| `\sin` | $\sin$ | `\cos` | $\cos$ |
| `\tan` | $\tan$ | `\cot` | $\cot$ |
| `\log` | $\log$ | `\ln` | $\ln$ |
| `\exp` | $\exp$ | `\lim` | $\lim$ |
| `\max` | $\max$ | `\min` | $\min$ |

---

## 杂项符号

| 语法 | 效果 | 语法 | 效果 |
|------|------|------|------|
| `\infty` | $\infty$ | `\partial` | $\partial$ |
| `\nabla` | $\nabla$ | `\forall` | $\forall$ |
| `\exists` | $\exists$ | `\neg` | $\neg$ |
| `\angle` | $\angle$ | `\triangle` | $\triangle$ |
| `\star` | $\star$ | `\cdot` | $\cdot$ |
| `\times` | $\times$ | `\div` | $\div$ |
| `\pm` | $\pm$ | `\mp` | $\mp$ |
| `\circ` | $\circ$ | `\bullet` | $\bullet$ |

---

## 括号与定界符

| 语法 | 效果 | 语法 | 效果 |
|------|------|------|------|
| `( )` | $( )$ | `[ ]` | $[ ]$ |
| `\lbrace \rbrace` | $\lbrace \rbrace$ | `\langle \rangle` | $\langle \rangle$ |
| `\left( ... \right)` | $\left( ... \right)$ | `\left[ ... \right]` | $\left[ ... \right]$ |
| `\left\{ ... \right\}` | $\left\{ ... \right\}$ |  |  |

语法：`\left| ... \right|`
效果：$\left| ... \right|$

---

## 空格

| 语法 | 效果 | 说明 |
|------|------|------|
| `a \quad b` | $a \quad b$ | 大空格 |
| `a \qquad b` | $a \qquad b$ | 极大空格 |
| `a \, b` | $a \, b$ | 小空格 |
| `a \; b` | $a \; b$ | 中等空格 |
| `a \! b` | $a \! b$ | 负空格 (收紧) |

---

## 对齐 (align 环境)

```latex
\begin{align}
x &= a + b \\
  &= c + d \\
  &= e + f
\end{align}
```

效果：
$$\begin{align}
x &= a + b \\
  &= c + d \\
  &= e + f
\end{align}$$

---

## 常用公式示例

### 欧拉公式
```
$e^{i\pi} + 1 = 0$
```
$e^{i\pi} + 1 = 0$

### 勾股定理
```
$$a^2 + b^2 = c^2$$
```
$$a^2 + b^2 = c^2$$

### 积分
```
$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$
```
$$\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}$$

### 矩阵
```
$$\begin{pmatrix} a & b \\ c & d \end{pmatrix}^{-1} = \frac{1}{ad-bc} \begin{pmatrix} d & -b \\ -c & a \end{pmatrix}$$
```
$$\begin{pmatrix} a & b \\ c & d \end{pmatrix}^{-1} = \frac{1}{ad-bc} \begin{pmatrix} d & -b \\ -c & a \end{pmatrix}$$

### 求和与积分组合
```
$$\sum_{i=1}^{n} \int_{0}^{1} f_i(x) dx$$
```
$$\sum_{i=1}^{n} \int_{0}^{1} f_i(x) dx$$
