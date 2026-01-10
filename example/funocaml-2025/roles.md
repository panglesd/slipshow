<style>
    :root {
      --bg: #f7f8fb;
      --ink: #0d0f14;
      --muted: #5b6473;
      --accent: #5b4dff;
      --stroke: #e6e8ef;
      --card: #ffffff;
      --shadow: 0 4px 12px rgba(18, 20, 27, .06);
      --radius: 14px;
    }
    p.lede {
      margin-top: 0;
      color: var(--muted);
    }
    .notshowing .person {
    opacity: 0;
    }
    .teams {
      margin-top: 32px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
      gap: 24px;
    }
    .team {
      background: var(--card);
      border: 1px solid var(--stroke);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 16px 20px;
    }
    .team h2 {
      margin-top: 0;
      font-size: 20px;
      border-bottom: 1px solid var(--stroke);
      padding-bottom: 6px;
    }
    #roles ul {
      list-style: none;
      padding-left: 0;
      margin: 0;
    }
    #roles li {
      padding: 6px 0;
      display: flex;
      justify-content: space-between;
      border-bottom: 1px dashed var(--stroke);
    }
    #roles li:last-child { border-bottom: 0; }
    .role { font-weight: 600; }
    .person { color: var(--muted); }
  </style><div id=roles>
  <section class="teams">
    <div class="team">
      <h2>Engineering</h2>
      <ul>
        <li><span class="role">Back-end engineer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Front-end engineer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Full-stack engineer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">MacOS specialist</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">UI/UX designer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">QA / Tester</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Release Manager</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">DevOps / Sysadmin</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
    <div class="team">
      <h2>Product & Community</h2>
      <ul>
        <li><span class="role">Product Manager</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Community manager</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Customer Success</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Data Analyst</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Research & Development (R&D)</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
    <div class="team">
      <h2>Support & Docs</h2>
      <ul>
        <li><span class="role">Technical Writer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Documentation Writer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Tech Support</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
    <div class="team">
      <h2>Operations</h2>
      <ul>
        <li><span class="role">Distribution</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Marketing</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Security Officer</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Finance / Accounting</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Legal Department</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
    <div class="team">
      <h2>People & Culture</h2>
      <ul>
        <li><span class="role">HR</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Human Resources (HR)</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Recruiter</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Ethics Board</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
    <div class="team">
      <h2>Leadership</h2>
      <ul>
        <li><span class="role">CEO / CTO / COO</span> <span class="person">Paul‑Elliot</span></li>
        <li><span class="role">Intern</span> <span class="person">Paul‑Elliot</span></li>
      </ul>
    </div>
  </section>
</div>
